FROM node:24-slim AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM base AS prod

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

COPY . ./
RUN pnpm run build

FROM nginx:alpine
WORKDIR /app
COPY --from=prod /app/dist /usr/share/nginx/html
COPY --from=prod /app/assets/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
