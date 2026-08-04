#!/usr/bin/env node
/*
 parse_office.mjs — extract text + tables from docx/xlsx/pptx to md/txt,
 using ONLY Node.js built-ins (node:zlib, node:fs). No npm install.
 Implements a minimal ZIP reader (local-file-header + DEFLATE via zlib)
 and light XML text extraction — no third-party library.

 Usage: node parse_office.mjs <file> [--format md|txt] [--out PATH]
 Exit: 0 ok · 1 parse error · 2 usage
*/
import { readFileSync, writeFileSync } from "node:fs";
import { inflateRawSync } from "node:zlib";
import { basename, extname } from "node:path";

// ---- minimal ZIP: read entries via local file headers ----
function unzip(buf) {
  const files = {};
  let i = 0;
  while (i + 4 <= buf.length) {
    const sig = buf.readUInt32LE(i);
    if (sig !== 0x04034b50) break;                // local file header
    const method = buf.readUInt16LE(i + 8);
    const compSize = buf.readUInt32LE(i + 18);
    const nameLen = buf.readUInt16LE(i + 26);
    const extraLen = buf.readUInt16LE(i + 28);
    const name = buf.toString("utf8", i + 30, i + 30 + nameLen);
    const dataStart = i + 30 + nameLen + extraLen;
    const raw = buf.subarray(dataStart, dataStart + compSize);
    if (compSize > 0) {
      files[name] = method === 8 ? inflateRawSync(raw) : Buffer.from(raw);
    }
    i = dataStart + compSize;
  }
  // fallback: some writers use data descriptors (size 0 in header) —
  // then use the central directory instead
  if (Object.keys(files).length === 0) return unzipViaCentral(buf);
  return files;
}
function unzipViaCentral(buf) {
  const files = {};
  const eocd = buf.lastIndexOf(Buffer.from([0x50,0x4b,0x05,0x06]));
  if (eocd < 0) return files;
  let cd = buf.readUInt32LE(eocd + 16);
  const count = buf.readUInt16LE(eocd + 10);
  for (let n = 0; n < count; n++) {
    const method = buf.readUInt16LE(cd + 10);
    const compSize = buf.readUInt32LE(cd + 20);
    const nameLen = buf.readUInt16LE(cd + 28);
    const extraLen = buf.readUInt16LE(cd + 30);
    const cmtLen = buf.readUInt16LE(cd + 32);
    const lho = buf.readUInt32LE(cd + 42);
    const name = buf.toString("utf8", cd + 46, cd + 46 + nameLen);
    const lNameLen = buf.readUInt16LE(lho + 26);
    const lExtraLen = buf.readUInt16LE(lho + 28);
    const dataStart = lho + 30 + lNameLen + lExtraLen;
    const raw = buf.subarray(dataStart, dataStart + compSize);
    files[name] = method === 8 ? inflateRawSync(raw) : Buffer.from(raw);
    cd += 46 + nameLen + extraLen + cmtLen;
  }
  return files;
}

const tOf = (xml) =>
  [...xml.matchAll(/<(?:[wa]:)?t(?:\s[^>]*)?>([\s\S]*?)<\/(?:[wa]:)?t>/g)]
    .map((m) => decode(m[1])).join("");
const decode = (s) => s.replace(/&amp;/g,"&").replace(/&lt;/g,"<")
  .replace(/&gt;/g,">").replace(/&quot;/g,'"').replace(/&apos;/g,"'");

function table(rows, fmt) {
  rows = rows.filter((r) => r.length);
  if (!rows.length) return "";
  if (fmt === "txt") return rows.map((r) => r.join(" | ")).join("\n");
  const w = Math.max(...rows.map((r) => r.length));
  rows = rows.map((r) => [...r, ...Array(w - r.length).fill("")]);
  const esc = (c) => c.replace(/\|/g, "\\|").replace(/\n/g, " ");
  const out = ["| " + rows[0].map(esc).join(" | ") + " |",
               "| " + rows[0].map(() => "---").join(" | ") + " |"];
  for (const r of rows.slice(1)) out.push("| " + r.map(esc).join(" | ") + " |");
  return out.join("\n");
}

function docx(files, fmt) {
  const xml = files["word/document.xml"]?.toString("utf8") || "";
  const out = [];
  // paragraphs and tables in document order
  const re = /<w:tbl>[\s\S]*?<\/w:tbl>|<w:p\b[\s\S]*?<\/w:p>/g;
  for (const m of xml.matchAll(re)) {
    const chunk = m[0];
    if (chunk.startsWith("<w:tbl")) {
      const rows = [...chunk.matchAll(/<w:tr\b[\s\S]*?<\/w:tr>/g)].map((tr) =>
        [...tr[0].matchAll(/<w:tc\b[\s\S]*?<\/w:tc>/g)].map((tc) => tOf(tc[0]).trim()));
      out.push(table(rows, fmt));
    } else {
      const t = tOf(chunk).trim();
      if (t) out.push(t);
    }
  }
  return out.join("\n\n");
}
function xlsx(files, fmt) {
  const shared = [];
  const ss = files["xl/sharedStrings.xml"]?.toString("utf8");
  if (ss) for (const m of ss.matchAll(/<si>([\s\S]*?)<\/si>/g)) shared.push(tOf(m[1]));
  const blocks = [];
  for (const name of Object.keys(files).filter((f) => /xl\/worksheets\/sheet\d+\.xml$/.test(f)).sort()) {
    const ws = files[name].toString("utf8");
    const rows = [];
    for (const rm of ws.matchAll(/<row\b[\s\S]*?<\/row>/g)) {
      const cells = [];
      for (const cm of rm[0].matchAll(/<c\b([^>]*)>([\s\S]*?)<\/c>/g)) {
        const attr = cm[1], body = cm[2];
        if (/t="inlineStr"/.test(attr)) {
          cells.push(tOf(body).trim());                 // <is><t>...</t></is>
        } else if (/t="s"/.test(attr)) {
          const v = (body.match(/<v>([\s\S]*?)<\/v>/) || [])[1] || "";
          cells.push(shared[+v] || "");
        } else {
          const v = (body.match(/<v>([\s\S]*?)<\/v>/) || [])[1] || "";
          cells.push(decode(v));
        }
      }
      rows.push(cells);
    }
    const label = basename(name).replace(".xml", "");
    blocks.push((fmt === "md" ? `## ${label}` : `[${label}]`) + "\n\n" + table(rows, fmt));
  }
  return blocks.join("\n\n");
}
function pptx(files, fmt) {
  const slides = Object.keys(files)
    .filter((f) => /ppt\/slides\/slide\d+\.xml$/.test(f))
    .sort((a, b) => (+a.match(/\d+/)) - (+b.match(/\d+/)));
  return slides.map((s, i) => {
    const lines = [...files[s].toString("utf8").matchAll(/<a:t[^>]*>([\s\S]*?)<\/a:t>/g)]
      .map((m) => decode(m[1]).trim()).filter(Boolean);
    const h = fmt === "md" ? `## Slide ${i + 1}` : `--- Slide ${i + 1} ---`;
    return lines.length ? h + "\n\n" + lines.join("\n") : h;
  }).join("\n\n");
}

const args = process.argv.slice(2);
if (!args.length) { console.error("usage: parse_office.mjs <file> [--format md|txt] [--out PATH]"); process.exit(2); }
const file = args[0];
const fmt = args.includes("--format") ? args[args.indexOf("--format") + 1] : "md";
const out = args.includes("--out") ? args[args.indexOf("--out") + 1] : null;
const ext = extname(file).toLowerCase();
const H = { ".docx": docx, ".xlsx": xlsx, ".pptx": pptx };
if (!(ext in H)) { console.error(`parse_office: unsupported ${ext}`); process.exit(2); }
try {
  const files = unzip(readFileSync(file));
  const text = H[ext](files, fmt);
  if (out) { writeFileSync(out, text); console.error(`wrote ${out} (${text.length} chars)`); }
  else process.stdout.write(text + "\n");
} catch (e) { console.error("parse_office:", e.message); process.exit(1); }
