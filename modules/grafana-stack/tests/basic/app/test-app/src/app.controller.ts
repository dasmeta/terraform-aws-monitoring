import { Controller, Get, Param, All } from '@nestjs/common';
import { AppService } from './app.service';
var AWS = require('aws-sdk');

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @All("/:message?")
  getHello(@Param('message') message?: string) {
    return this.appService.getHello(message);
  }
}
