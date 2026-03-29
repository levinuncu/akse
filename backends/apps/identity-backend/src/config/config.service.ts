import path from 'node:path';
import { SharedConfig, SharedConfigSchema } from '@app/common/config';
import { config } from 'dotenv';
import Joi from 'joi';

import { Injectable } from '@nestjs/common';

config({ override: true, path: path.join(__dirname, '/../../../apps/identity-backend/.env.local') });

@Injectable()
export class ConfigService extends SharedConfig {
  readonly app = {
    baseUrl: process.env.APP_BASE_URL ?? '',
    port: Number(process.env.APP_PORT) || 3000,
  };
}

const ConfigServiceSchema = SharedConfigSchema.keys({
  app: Joi.object({
    baseUrl: Joi.string().uri().required(),
    port: Joi.number().port().required(),
  }).required(),
});

Joi.assert(new ConfigService(), ConfigServiceSchema, 'Invalid configuration');
