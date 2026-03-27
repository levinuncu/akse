import path from 'node:path';
import { config } from 'dotenv';
import Joi from 'joi';

import type { LogLevel } from '@nestjs/common';
import { LOG_LEVELS } from '@nestjs/common';

config({ path: path.join(`${__dirname}/../../../../.env.local`) });

export class SharedConfig {
  readonly logger = {
    level: (process.env.LOG_LEVEL ?? 'log') as LogLevel,
  };

  readonly applicationInsights = {
    connectionString: process.env.APPLICATIONINSIGHTS_CONNECTION_STRING ?? '',
  };

  readonly postgres = {
    database: process.env.POSTGRES_DB ?? '',
    host: process.env.POSTGRES_HOST ?? '',
    password: process.env.POSTGRES_PASSWORD ?? '',
    port: Number(process.env.POSTGRES_PORT) || 5432,
    username: process.env.POSTGRES_USER ?? '',
  };

  readonly rabbitMq = {
    host: process.env.RABBITMQ_HOST ?? '',
    password: process.env.RABBITMQ_PASSWORD ?? '',
    port: Number(process.env.RABBITMQ_PORT) || 5672,
    username: process.env.RABBITMQ_USER ?? '',
  };

  readonly keycloak = {
    clientId: process.env.KEYCLOAK_CLIENT_ID ?? '',
    realm: process.env.KEYCLOAK_REALM ?? '',
    secret: process.env.KEYCLOAK_SECRET ?? '',
    url: process.env.KEYCLOAK_URL ?? '',
  };
}

export const SharedConfigSchema = Joi.object({
  applicationInsights: Joi.object({
    connectionString: Joi.string().required(),
  }).required(),
  keycloak: Joi.object({
    clientId: Joi.string().required(),
    realm: Joi.string().required(),
    secret: Joi.string().required(),
    url: Joi.string().uri().required(),
  }).required(),
  logger: Joi.object({
    level: Joi.string().valid(...LOG_LEVELS),
  }).required(),
  postgres: Joi.object({
    database: Joi.string().required(),
    host: Joi.string().hostname().required(),
    password: Joi.string().required(),
    port: Joi.number().port().required(),
    username: Joi.string().required(),
  }).required(),
  rabbitMq: Joi.object({
    host: Joi.string().hostname().required(),
    password: Joi.string().required(),
    port: Joi.number().port().required(),
    username: Joi.string().required(),
  }).required(),
}).required();

Joi.assert(new SharedConfig(), SharedConfigSchema, 'Invalid configuration');
