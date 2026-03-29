FROM node:24-slim AS base
ARG APP_NAME
ARG PORT=3000
ENV APP_PORT=${PORT}

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM base AS prod
WORKDIR /app

COPY ./backends/pnpm-lock.yaml ./
RUN pnpm fetch --prod

COPY ./backends ./
RUN pnpm run build ${APP_NAME}

FROM base
WORKDIR /app

COPY --from=prod /app/node_modules ./node_modules
COPY --from=prod /app/dist/apps/${APP_NAME} ./dist

CMD ["node", "dist/main.js"]