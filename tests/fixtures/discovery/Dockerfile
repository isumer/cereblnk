FROM node:22-alpine AS web
WORKDIR /web

FROM eclipse-temurin:21-jre
COPY --from=web /web/dist /app/static
