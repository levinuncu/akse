import path from 'node:path';

export const API_PREFIX = '/service/identity/v1/api';
export const TABLE_PREFIX = 'identity__';

export const MIGRATIONS_TABLE_NAME = `${TABLE_PREFIX}migrations`;
export const MIGRATION_PATH = path.join(__dirname, '/migrations/*.{ts,js}');

export const ENTITY_PATH = path.join(__dirname, '/**/*.entity.{ts,js}');
