import type { KeycloakUser } from '@app/common/auth';
import Joi from 'joi';
import { AuthenticatedUser } from 'nest-keycloak-connect';
import { JoiPipe } from 'nestjs-joi';

import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import {
  ApiBody,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
} from '@nestjs/swagger';

import { CreateTodoDto, CreateTodoDtoSchema } from './dto/create-todo.dto';
import { GetTodoDto } from './dto/get-todo.dto';
import { TodoService } from './todo.service';

@Controller('todos')
export class TodoController {
  constructor(private readonly todoService: TodoService) {}

  @ApiBody({ type: CreateTodoDto })
  @ApiCreatedResponse({ description: 'Created the todo' })
  @ApiOperation({ summary: 'Create a new todo' })
  @Post()
  async createOne(
    @Body(new JoiPipe(CreateTodoDtoSchema)) createTodoDto: CreateTodoDto,
    @AuthenticatedUser() user: KeycloakUser,
  ): Promise<void> {
    await this.todoService.createOne(createTodoDto, user);
  }

  @ApiNotFoundResponse({
    description: 'Todo with the id not found',
  })
  @ApiOkResponse({ type: GetTodoDto })
  @ApiOperation({ summary: 'Get a todo by its id' })
  @ApiParam({
    description: 'Id of the todo',
    format: 'uuid',
    name: 'id',
    type: 'string',
  })
  @Get(':id')
  async findOne(@Param('id', new JoiPipe(Joi.string().uuid().required())) id: string): Promise<GetTodoDto> {
    const todo = await this.todoService.findOneOrFail(id);

    return {
      id: todo.id,
      name: todo.name,
    };
  }

  @ApiOkResponse({ type: [GetTodoDto] })
  @ApiOperation({ summary: 'Get all todos' })
  @Get()
  async findAll(): Promise<GetTodoDto[]> {
    const todos = await this.todoService.findAll();

    return todos.map((todo) => ({
      id: todo.id,
      name: todo.name,
    }));
  }

  @ApiForbiddenResponse({ description: 'Not allowed to delete the todo' })
  @ApiNotFoundResponse({
    description: 'Todo with the id not found',
  })
  @ApiOkResponse({ description: 'Deleted the todo' })
  @ApiOperation({ summary: 'Delete a todo by its id' })
  @ApiParam({
    description: 'Id of the todo',
    format: 'uuid',
    name: 'id',
    type: 'string',
  })
  @Delete(':id')
  async deleteOne(
    @Param('id', new JoiPipe(Joi.string().uuid().required())) id: string,
    @AuthenticatedUser() user: KeycloakUser,
  ): Promise<void> {
    await this.todoService.deleteOneOrFail(id, user);
  }
}
