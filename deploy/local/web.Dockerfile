# syntax=docker/dockerfile:1.7
FROM node:22-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ARG VITE_API_BASE_URL=http://127.0.0.1:8090
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ARG NITRO_PRESET=node-server
ENV NITRO_PRESET=$NITRO_PRESET
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=build /src/.output ./.output
ENV NODE_ENV=production HOST=0.0.0.0 PORT=8080
EXPOSE 8080
ENTRYPOINT ["node", ".output/server/index.mjs"]
