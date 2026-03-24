import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  ParseUUIDPipe,
} from '@nestjs/common';
import { TodoService } from './todo.service';
import { CreateTodoDto } from './dto/create-todo.dto';
import { TodoEntity } from './entities/todo.entity';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';

@Controller('todos')
@ApiTags('todos')
export class TodoController {
  constructor(private readonly todoService: TodoService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new todo' })
  @ApiResponse({ status: 201, description: 'Created the todo' })
  async create(@Body() createTodoDto: CreateTodoDto): Promise<void> {
    await this.todoService.create(createTodoDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all todos' })
  @ApiResponse({ status: 200, type: [TodoEntity] })
  async findAll(): Promise<TodoEntity[]> {
    return this.todoService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get one todo by its id' })
  @ApiParam({
    name: 'id',
    type: 'string',
    format: 'uuid',
    description: 'Id of the todo',
  })
  @ApiResponse({ status: 200, type: TodoEntity })
  @ApiResponse({ status: 400, description: 'Invalid id provided' })
  @ApiResponse({ status: 404, description: 'Todo with the id not found' })
  async findOne(@Param('id', ParseUUIDPipe) id: string): Promise<TodoEntity> {
    return this.todoService.findOne(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a todo by its id' })
  @ApiParam({
    name: 'id',
    type: 'string',
    format: 'uuid',
    description: 'Id of the todo',
  })
  @ApiResponse({ status: 204, description: 'Deleted the todo' })
  @ApiResponse({ status: 400, description: 'Invalid id provided' })
  @ApiResponse({ status: 404, description: 'Todo with the id not found' })
  async remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    await this.todoService.remove(id);
  }
}
