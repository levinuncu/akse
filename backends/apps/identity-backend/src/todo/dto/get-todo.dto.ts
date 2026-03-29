import { ApiProperty } from '@nestjs/swagger';

export class GetTodoDto {
  @ApiProperty({
    description: 'Id of the todo',
    format: 'uuid',
    type: 'string',
  })
  id: string;

  @ApiProperty({ description: 'Name of the todo' })
  name: string;
}
