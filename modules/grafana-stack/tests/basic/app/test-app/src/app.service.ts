import { HttpService } from '@nestjs/axios';
import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { MessagesService } from './messages/messages.service';
import { catchError, firstValueFrom } from 'rxjs';
import { AxiosError } from 'axios';
// var AWS = require('aws-sdk');
// import * as AWS from "@aws-sdk/client-sns";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";


@Injectable()
export class AppService {
  constructor(
    private messagesService: MessagesService,
    private readonly httpService: HttpService
  ) { }


  async getHello(message) {
    let printMessage = `Hello World! with message ${message}`

    if (process.env.PUBLISH_TO_SNS_ENABLED === "true") {
      let result = await this.publishMessageToSNS(printMessage);

      console.log("publishMessageToSNS", { result })
    }

    if (process.env.INSERT_ITO_RDS_ENABLED === "true") {
      let result = await this.writeMessageToRDS(printMessage);

      console.log("writeMessageToRDS", { result })
    }

    if (process.env.CALL_TO_SERVICE_ENABLED === "true") {
      let result = await this.callToService(printMessage);

      console.log("callToService", { result })
    }

    return printMessage;
  }

  async publishMessageToSNS(message) {
    console.log("run publishMessageToSNS")

    this.randomErrorWithHttpStatus();

    const client = new SNSClient({
      region: 'eu-central-1',
      logger: console,
      // apiVersion: '2010-03-31'
    });

    const command = new PublishCommand({
      Message: message,
      TopicArn: process.env.TOPIC_ARN,
      MessageAttributes: {
        myCustomAttribute: {
          DataType: "String",
          StringValue: "this is test attribute"
        }
      }
    })

    // // Create publish parameters
    // var params = {
    //   Message: message, /* required */
    //   TopicArn: process.env.TOPIC_ARN
    // };

    // // Create promise and SNS service object
    // var publishTextPromise = new AWS.SNS({apiVersion: '2010-03-31'}).publish(params).promise();

    // // Handle promise's fulfilled/rejected states
    // return publishTextPromise.then(
    //   function(data) {
    //     console.log(`Message ${params.Message} sent to the topic ${params.TopicArn}`);
    //     console.log("MessageID is " + data.MessageId);
    //   }).catch(
    //     function(err) {
    //     console.error(err, err.stack);
    //     });

    try {
      const data = await client.send(command);
      console.info("SNS publish success", {data})
    } catch (error) {
      console.error("SNS publish failed", {error})
    }

  }

  async writeMessageToRDS(message: string) {
    console.log("run writeMessageToRDS")

    this.randomErrorWithHttpStatus();

    return this.messagesService.create(message);
  }

  async callToService(message: string) {
    let forwardMessage = encodeURIComponent(`/${message}-called-from-${process.env.SERVICE_NAME}`);
    console.log("run callToService", process.env.CALL_TO_SERVICE_URL + `/${forwardMessage}`)

    this.randomErrorWithHttpStatus();

    const { data } = await firstValueFrom(
      this.httpService.get(process.env.CALL_TO_SERVICE_URL + `/${forwardMessage}`).pipe(
        catchError((error: AxiosError) => {
          console.error(error.response.data);
          throw 'An error happened!';
        }),
      ),
    );
    return data;
  }

  randomErrorWithHttpStatus() {
    if (process.env.RANDOM_ERROR_ENABLED !== "true") {
      return;
    }

    console.log("run randomErrorWithHttpStatus");

    const statusToChance = {
      "OK": 30,
      "NOT_FOUND": 20,
      "BAD_REQUEST": 15,
      "UNAUTHORIZED": 15,
      "INTERNAL_SERVER_ERROR": 10,
      "SERVICE_UNAVAILABLE": 10,
    };

    var random = Math.random() * 100;
    let counter = 0;
    let choiceStatus = "OK"

    for (const status in statusToChance) {
      let chance = statusToChance[status];
      if (counter + random < chance) {
        choiceStatus = status;
      }
    }

    if (choiceStatus == "OK") return;

    // throw new Error(choiceStatus)
    throw new HttpException(choiceStatus, HttpStatus[choiceStatus])
  }
}
