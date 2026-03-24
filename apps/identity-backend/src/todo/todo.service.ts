import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CreateTodoDto } from './dto/create-todo.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { TodoEntity } from './entities/todo.entity';
import { Repository } from 'typeorm';

@Injectable()
export class TodoService {
  private readonly logger = new Logger(TodoService.name);

  constructor(
    @InjectRepository(TodoEntity)
    private readonly todoRepository: Repository<TodoEntity>,
  ) {}

  async create(createTodoDto: CreateTodoDto): Promise<void> {
    const todoData = this.todoRepository.create(createTodoDto);
    await this.todoRepository.save(todoData);
    this.logger.log(`Created todo with name "${createTodoDto.name}"`);
  }

  async findAll(): Promise<TodoEntity[]> {
    return await this.todoRepository.find();
  }

  async findOne(id: string): Promise<TodoEntity> {
    const todoData = await this.todoRepository.findOneBy({ id });
    if (!todoData) {
      throw new NotFoundException(`Todo with id "${id}" not found.`);
    }

    return todoData;
  }

  async remove(id: string): Promise<void> {
    const todo = await this.findOne(id);
    await this.todoRepository.remove(todo);
    this.logger.log(`Removed todo with id "${id}"`);
  }
}
