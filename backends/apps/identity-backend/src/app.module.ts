import { ACCESS_TOKEN_COOKIE_KEY } from '@app/common/auth';
import { GlobalExceptionFilter, TypeOrmExceptionFilter } from '@app/common/filters';
import { RabbitMQModule } from '@golevelup/nestjs-rabbitmq';
import { TelemetryClient } from 'applicationinsights';
import * as azureAppInsights from 'applicationinsights';
import {
  AuthGuard,
  KeycloakConnectModule,
  PolicyEnforcementMode,
  RoleGuard,
  TokenValidation,
} from 'nest-keycloak-connect';
import { JoiPipeModule } from 'nestjs-joi';
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';

import { Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthModule } from './auth/auth.module';
import { ConfigModule } from './config/config.module';
import { ConfigService } from './config/config.service';
import { ENTITY_PATH, TABLE_PREFIX } from './definitions.constants';
import { TodoModule } from './todo/todo.module';

@Module({
  imports: [
    ConfigModule,
    JoiPipeModule,
    ThrottlerModule.forRoot({
      throttlers: [
        {
          limit: 5,
          ttl: 60_000,
        },
      ],
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        autoLoadEntities: true,
        database: configService.postgres.database,
        entities: [ENTITY_PATH],
        entityPrefix: TABLE_PREFIX,
        host: configService.postgres.host,
        namingStrategy: new SnakeNamingStrategy(),
        password: configService.postgres.password,
        port: configService.postgres.port,
        synchronize: true,
        type: 'postgres',
        username: configService.postgres.username,
        // migrationsTableName: MIGRATIONS_TABLE_NAME,
        // migrationsRun: true,
        // migrations: [MIGRATION_PATH],
      }),
    }),
    RabbitMQModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        exchanges: [],
        prefetchCount: 1,
        uri: `amqp://${encodeURIComponent(configService.rabbitmq.username)}:${encodeURIComponent(configService.rabbitmq.password)}@${configService.rabbitmq.host}:${configService.rabbitmq.port}`,
      }),
    }),
    KeycloakConnectModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        authServerUrl: configService.keycloak.url,
        clientId: configService.keycloak.clientId,
        cookieKey: ACCESS_TOKEN_COOKIE_KEY,
        policyEnforcement: PolicyEnforcementMode.ENFORCING,
        realm: configService.keycloak.realm,
        secret: configService.keycloak.secret,
        tokenValidation: TokenValidation.ONLINE,
        useNestLogger: true,
      }),
    }),
    AuthModule,
    TodoModule,
  ],
  providers: [
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
    {
      provide: APP_FILTER,
      useClass: TypeOrmExceptionFilter,
    },
    {
      provide: TelemetryClient,
      useFactory: (): TelemetryClient => azureAppInsights.defaultClient,
    },
    {
      provide: APP_GUARD,
      useClass: AuthGuard,
    },
    // {
    //   provide: APP_GUARD,
    //   useClass: ResourceGuard,
    // },
    {
      provide: APP_GUARD,
      useClass: RoleGuard,
    },
  ],
})
export class AppModule {}
