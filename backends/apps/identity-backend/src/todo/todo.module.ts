import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { TodoEntity } from './entities/todo.entity';
import { TodoController } from './todo.controller';
import { TodoService } from './todo.service';

@Module({
  controllers: [TodoController],
  imports: [TypeOrmModule.forFeature([TodoEntity])],
  providers: [TodoService],
})
export class TodoModule {}
