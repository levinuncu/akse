import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';

import { ConfigModule } from '../config/config.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  controllers: [AuthController],
  imports: [HttpModule, ConfigModule],
  providers: [AuthService],
})
export class AuthModule {}
