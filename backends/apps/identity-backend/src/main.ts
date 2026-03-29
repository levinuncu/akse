import * as azureAppInsights from 'applicationinsights';
import cookieParser from 'cookie-parser';

import { ConsoleLogger, HttpStatus, Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module';
import { ConfigService } from './config/config.service';
import { API_PREFIX } from './definitions.constants';

const configService = new ConfigService();

azureAppInsights
  .setup(configService.applicationInsights.connectionString)
  .setAutoDependencyCorrelation(true)
  .setAutoCollectRequests(true)
  .setAutoCollectPerformance(true, true)
  .setAutoCollectExceptions(true)
  .setAutoCollectDependencies(true)
  .setAutoCollectConsole(true, true)
  .setUseDiskRetryCaching(true)
  .setSendLiveMetrics(true)
  .setDistributedTracingMode(azureAppInsights.DistributedTracingModes.AI_AND_W3C)
  .start();

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);

  app.useLogger(
    new ConsoleLogger({
      logLevels: [configService.logger.level],
      timestamp: true,
    }),
  );

  app.use(cookieParser());
  // TODO: Setup cors

  app.setGlobalPrefix(API_PREFIX);

  SwaggerModule.setup(
    `${API_PREFIX}/docs`,
    app,
    SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle('Identity Backend')
        .setVersion('1.0')
        .addServer(API_PREFIX)
        .addGlobalResponse({
          description: 'Not authorized',
          status: HttpStatus.UNAUTHORIZED,
        })
        .addGlobalResponse({
          description: 'Internal server error',
          status: HttpStatus.INTERNAL_SERVER_ERROR,
        })
        .build(),
      {
        ignoreGlobalPrefix: true,
      },
    ),
  );

  await app.listen(configService.app.port);

  const logger = new Logger();
  logger.log(`Listening on port ${configService.app.port}`);
}

void bootstrap();
