import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MessageEntity } from './message.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(MessageEntity)
    private repository: Repository<MessageEntity>,
  ) { }
  
  findOne(id: number): Promise<MessageEntity> {
    return this.repository.findOneBy({ id });
  }

  create(content: string): Promise<MessageEntity> {
    let message = new MessageEntity();

    message.content = content;
    return message.save();
  }
}
