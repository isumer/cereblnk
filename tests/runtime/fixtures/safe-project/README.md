# safe-project

A disposable target for runtime probes. Copy it to a temporary directory
before use; never point a probe at this repository.

It exists so a veto stage has something harmless to be refused against.
The guard under test does not care what the file contains — only that a
tool call was attempted and stopped — so nothing here needs to be
interesting, and nothing here should be valuable.
