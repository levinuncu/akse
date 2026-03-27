import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'todo' })
export class TodoEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 255, type: 'char' })
  name: string;

  @Column({ length: 255, type: 'char' })
  @Index()
  userId: string;
}
