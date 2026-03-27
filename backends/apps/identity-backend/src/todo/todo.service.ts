import { KeycloakRole, KeycloakUser } from '@app/common/auth';
import { Repository } from 'typeorm';

import { ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

import { CreateTodoDto } from './dto/create-todo.dto';
import { TodoEntity } from './entities/todo.entity';

@Injectable()
export class TodoService {
  private readonly logger = new Logger(TodoService.name);

  constructor(
    @InjectRepository(TodoEntity)
    private readonly todoRepository: Repository<TodoEntity>,
  ) {}

  async createOne(createTodoDto: CreateTodoDto, user: KeycloakUser): Promise<void> {
    const todo = this.todoRepository.create({
      ...createTodoDto,
      userId: user.sub,
    });

    const createdTodo = await this.todoRepository.save(todo);
    this.logger.log('Created todo', createdTodo);
  }

  async findAll(): Promise<TodoEntity[]> {
    return await this.todoRepository.find();
  }

  async findOneOrFail(id: string): Promise<TodoEntity> {
    return await this.todoRepository.findOneByOrFail({ id });
  }

  async deleteOneOrFail(id: string, user: KeycloakUser): Promise<void> {
    const todo = await this.findOneOrFail(id);
    if (todo.userId !== user.sub && !user.realm_access.roles.includes(KeycloakRole.ADMIN)) {
      throw new ForbiddenException('You are not allowed to delete the todo');
    }

    await this.todoRepository.remove(todo);
    this.logger.log('Deleted todo', todo);
  }
}
