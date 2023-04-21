console.log('Loading function');
// const axios = require('axios');
// const AWSXRay = require('aws-xray-sdk');
// AWSXRay.config([AWSXRay.plugins.EC2Plugin,AWSXRay.plugins.ElasticBeanstalkPlugin]);

// capture mysql queries
var mysql = require('mysql');

// Capture all outgoing https requests
// AWSXRay.captureHTTPsGlobal(require('https'));
// AWSXRay.captureHTTPsGlobal(require('http'));
const https = require('https');

// AWSXRay.capturePromise();

const {_spanProcessor} = require("./tracing")

exports.handler = async (event, context) => {
  console.log('Received event:', JSON.stringify(event, null, 2));
  const message = event.Records[0].Sns.Message;
  console.log('From SNS:', message);


  // do http request to node js sample service 3
  const endpoint = 'https://test-app.sb-ak.proalpha.dev/sss/request-to-service3-from-lambda';
  // const endpoint = 'https://cht.sh/help';

  // let results = await axios.request({
  //   method: 'get',
  //   maxBodyLength: Infinity,
  //   url: 'https://test-app.sb-ak.proalpha.dev/sss/request-to-service3-from-lambda',
  //   headers: {}
  // });

  const httpPromise = new Promise((resolve, reject) => { 
    https.get(endpoint, (response) => {
      response.on('data', (data) => {
        resolve(data)
      });
  
      response.on('error', (err) => {
        reject(`Encountered error while making HTTPS request: ${err}`);
      });
  
      response.on('end', () => {
        console.log(`Successfully reached ${endpoint}.`);
      });
    });
  })

  let results = await httpPromise

  console.log("call to service 3", {results})

  // Do mysql select query
  var connection = mysql.createConnection({
    host     : process.env.MYSQL_HOST,
    user     : process.env.MYSQL_USERNAME,
    password : process.env.MYSQL_PASSWORD,
    port     : "3306",
    database : process.env.MYSQL_DATABASE
  });

  const mysqlPromise = new Promise((resolve) => {
    connection.connect(function (err) {
      if (err) throw err;
      connection.query("SELECT count(*) FROM message_entity", function (err, result, fields) {
        if (err) throw err;

        resolve(result);
        console.log(result);
      });
    });
  })

  results = await mysqlPromise

  connection.end();

  console.log("Mysql query", { results })

  console.log("start force flush tracing spans")
  await _spanProcessor.forceFlush();
  console.log("finish force flush tracing spans")

  return message;
};
