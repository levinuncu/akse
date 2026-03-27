import type { CookieOptions, Request, Response } from 'express';
import { ACCESS_TOKEN_COOKIE_KEY, REFRESH_TOKEN_COOKIE_KEY } from '@app/common/auth';
import Joi from 'joi';
import { Public } from 'nest-keycloak-connect';
import { JoiPipe } from 'nestjs-joi';

import { Controller, Get, Query, Res, UnauthorizedException } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { AuthService } from './auth.service';
import { Cookie } from './decorators/cookie.decorator';

const ACCESS_TOKEN_COOKIE_OPTIONS: CookieOptions = {
  httpOnly: true,
  sameSite: 'strict',
  secure: true,
};
const REFRESH_TOKEN_COOKIE_OPTIONS: CookieOptions = {
  httpOnly: true,
  sameSite: 'strict',
  secure: true,
};

@ApiExcludeController()
@Controller('auth')
@Public()
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('callback')
  async callback(
    @Query('code', new JoiPipe(Joi.string().required())) authorizationCode: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<void> {
    const {
      access_token: accessToken,
      expires_in: expiresIn,
      refresh_expires_in: refreshExpiresIn,
      refresh_token: refreshToken,
    } = await this.authService.callback(authorizationCode);

    res.cookie(ACCESS_TOKEN_COOKIE_KEY, accessToken, {
      ...ACCESS_TOKEN_COOKIE_OPTIONS,
      maxAge: expiresIn * 1000,
    });
    res.cookie(REFRESH_TOKEN_COOKIE_KEY, refreshToken, {
      ...REFRESH_TOKEN_COOKIE_OPTIONS,
      maxAge: refreshExpiresIn * 1000,
    });
  }

  @Get('refresh')
  async refresh(
    @Res({ passthrough: true }) res: Response,
    @Cookie(REFRESH_TOKEN_COOKIE_KEY) currentRefreshToken?: string,
  ): Promise<void> {
    if (!currentRefreshToken) {
      throw new UnauthorizedException();
    }

    try {
      const {
        access_token: accessToken,
        expires_in: expiresIn,
        refresh_expires_in: refreshExpiresIn,
        refresh_token: newRefreshToken,
      } = await this.authService.refresh(currentRefreshToken);

      res.cookie(ACCESS_TOKEN_COOKIE_KEY, accessToken, {
        ...ACCESS_TOKEN_COOKIE_OPTIONS,
        maxAge: expiresIn * 1000,
      });
      res.cookie(REFRESH_TOKEN_COOKIE_KEY, newRefreshToken, {
        ...REFRESH_TOKEN_COOKIE_OPTIONS,
        maxAge: refreshExpiresIn * 1000,
      });
    } catch (error) {
      res.clearCookie(ACCESS_TOKEN_COOKIE_KEY, ACCESS_TOKEN_COOKIE_OPTIONS);
      res.clearCookie(REFRESH_TOKEN_COOKIE_KEY, REFRESH_TOKEN_COOKIE_OPTIONS);
      throw error;
    }
  }

  @Get('logout')
  async logout(
    @Res({ passthrough: true }) res: Response,
    @Cookie(REFRESH_TOKEN_COOKIE_KEY) refreshToken?: string,
  ): Promise<void> {
    if (!refreshToken) {
      throw new UnauthorizedException();
    }

    await this.authService.logout(refreshToken);
    res.clearCookie(ACCESS_TOKEN_COOKIE_KEY, ACCESS_TOKEN_COOKIE_OPTIONS);
    res.clearCookie(REFRESH_TOKEN_COOKIE_KEY, REFRESH_TOKEN_COOKIE_OPTIONS);
  }
}
