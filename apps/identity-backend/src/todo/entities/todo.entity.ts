import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class TodoEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;
}
