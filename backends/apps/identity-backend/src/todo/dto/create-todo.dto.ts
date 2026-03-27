import Joi from 'joi';

import { ApiProperty } from '@nestjs/swagger';

export class CreateTodoDto {
  @ApiProperty({ description: 'Name of the todo' })
  name: string;
}

export const CreateTodoDtoSchema = Joi.object({
  name: Joi.string().trim().required().max(255),
});
