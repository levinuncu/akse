import { KnownSeverityLevel, TelemetryClient } from 'applicationinsights';
import { isAxiosError } from 'axios';
import { Response } from 'express';

import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  constructor(private readonly telemetryClient: TelemetryClient) {}

  catch(exception: Error, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();

    if (isAxiosError(exception)) {
      if (exception.response) {
        response.status(exception.response.status).json({
          message: exception.response.statusText,
          statusCode: exception.response.status,
        });
      } else if (exception.request) {
        response.status(HttpStatus.BAD_REQUEST).json({
          message: 'Bad request',
          statusCode: HttpStatus.BAD_REQUEST,
        });
      } else {
        this.logger.error('Uncaught axios error', exception);

        response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
          message: 'Internal server error',
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        });
      }

      return;
    }

    if (exception instanceof HttpException) {
      response.status(exception.getStatus()).json({
        message: exception.message,
        statusCode: exception.getStatus(),
      });
      return;
    }

    this.logger.error('Uncaught error', exception);

    this.telemetryClient.trackException({
      exception,
      severity: KnownSeverityLevel.Critical,
    });

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      message: 'Internal server error',
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
    });
  }
}
