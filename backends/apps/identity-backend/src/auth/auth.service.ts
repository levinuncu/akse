import { firstValueFrom } from 'rxjs';
import urlJoin from 'url-join';

import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';

import { ConfigService } from '../config/config.service';
import { API_PREFIX } from '../definitions.constants';
import { TokenResponse } from './interfaces/token-response.interface';

@Injectable()
export class AuthService {
  private readonly tokenUrl!: string;
  private readonly redirectUri!: string;
  private readonly logoutUrl!: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.tokenUrl = urlJoin(
      configService.keycloak.url,
      'realms',
      configService.keycloak.realm,
      'protocol/openid-connect/token',
    );
    this.redirectUri = urlJoin(this.configService.app.baseUrl, API_PREFIX, 'auth/callback');
    this.logoutUrl = urlJoin(
      configService.keycloak.url,
      'realms',
      configService.keycloak.realm,
      'protocol/openid-connect/logout',
    );
  }

  async callback(authorizationCode: string): Promise<TokenResponse> {
    const { data } = await firstValueFrom(
      this.httpService.post<TokenResponse>(
        this.tokenUrl,
        new URLSearchParams({
          client_id: this.configService.keycloak.clientId,
          client_secret: this.configService.keycloak.secret,
          code: authorizationCode,
          grant_type: 'authorization_code',
          redirect_uri: this.redirectUri,
        }).toString(),
        { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
      ),
    );

    return data;
  }

  async refresh(refreshToken: string): Promise<TokenResponse> {
    const { data } = await firstValueFrom(
      this.httpService.post<TokenResponse>(
        this.tokenUrl,
        new URLSearchParams({
          client_id: this.configService.keycloak.clientId,
          client_secret: this.configService.keycloak.secret,
          grant_type: 'refresh_token',
          refresh_token: refreshToken,
        }).toString(),
        { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
      ),
    );

    return data;
  }

  async logout(refreshToken: string): Promise<void> {
    await firstValueFrom(
      this.httpService.post(
        this.logoutUrl,
        new URLSearchParams({
          client_id: this.configService.keycloak.clientId,
          client_secret: this.configService.keycloak.secret,
          refresh_token: refreshToken,
        }).toString(),
        { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
      ),
    );
  }
}
