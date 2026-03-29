import { KnownSeverityLevel, TelemetryClient } from 'applicationinsights';
import { Response } from 'express';
import { EntityNotFoundError, QueryFailedError } from 'typeorm';

import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus, Logger } from '@nestjs/common';

@Catch(QueryFailedError, EntityNotFoundError)
export class TypeOrmExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(TypeOrmExceptionFilter.name);

  constructor(private readonly telemetryClient: TelemetryClient) {}

  catch(exception: EntityNotFoundError | QueryFailedError, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();

    if (exception instanceof EntityNotFoundError) {
      response.status(HttpStatus.NOT_FOUND).json({
        message: 'Entity not found',
        statusCode: HttpStatus.NOT_FOUND,
      });
      return;
    }

    if (queryFailedGuard(exception)) {
      switch (exception.code) {
        case '23505': {
          response.status(HttpStatus.CONFLICT).json({
            message: 'Entity already exists',
            statusCode: HttpStatus.CONFLICT,
          });
          break;
        }
        default: {
          this.logger.error('Uncaught database error', exception);

          this.telemetryClient.trackException({
            exception,
            severity: KnownSeverityLevel.Critical,
          });

          response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
            message: 'Internal server error',
            statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          });
          break;
        }
      }
    }
  }
}

const queryFailedGuard = (err: unknown): err is { code: string } & QueryFailedError => err instanceof QueryFailedError;
