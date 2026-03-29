import type { Request } from 'express';

import type { ExecutionContext } from '@nestjs/common';
import { createParamDecorator } from '@nestjs/common';

export const Cookie = createParamDecorator((data: string, ctx: ExecutionContext) => {
  const request = ctx.switchToHttp().getRequest<Request>();
  const cookies = request.cookies as Record<string, unknown>;

  return cookies[data];
});
