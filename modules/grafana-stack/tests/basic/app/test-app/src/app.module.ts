import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MessagesModule } from './messages/messages.module';
import { HttpModule } from "@nestjs/axios";

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      port: 3306,
      host: process.env.MYSQL_HOST,
      username: process.env.MYSQL_USERNAME,
      password: process.env.MYSQL_PASSWORD,
      database: process.env.MYSQL_DATABASE,
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: true,
      logging: true,
      // migrationsTableName: "migrations",
      // migrations: [__dirname + '/migrations/*{.ts,.js}'],
      // cli: {
      //     migrationsDir: "src/migrations"
      // },
      // migrationsRun: true,
      entityPrefix: '',
    }),
    MessagesModule,
    HttpModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
