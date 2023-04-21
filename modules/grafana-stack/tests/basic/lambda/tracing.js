const { CompositePropagator, W3CTraceContextPropagator } = require('@opentelemetry/core');
const { B3InjectEncoding, B3Propagator } = require('@opentelemetry/propagator-b3');
const opentelemetry = require("@opentelemetry/sdk-node");
const { Resource } = require("@opentelemetry/resources");
const { SemanticResourceAttributes } = require("@opentelemetry/semantic-conventions");
const { BatchSpanProcessor, ConsoleSpanExporter} = require('@opentelemetry/sdk-trace-base');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { AWSXRayPropagator } = require("@opentelemetry/propagator-aws-xray");
const { AWSXRayIdGenerator } = require("@opentelemetry/id-generator-aws-xray");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");

const _resource = Resource.default().merge(new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: process.env.SERVICE_NAME, // here we set the app/service name which will be shown in traces
}));

console.log({"process.env.OTEL_RPC_ENDPOINT": process.env.OTEL_RPC_ENDPOINT})

const _traceExporter = new OTLPTraceExporter({ url: process.env.OTEL_RPC_ENDPOINT }); // here we set otel service path to push generated traces into
const _spanProcessor = new BatchSpanProcessor(_traceExporter);
// const _spanProcessor = new BatchSpanProcessor(new ConsoleSpanExporter());
const _tracerConfig = {
    idGenerator: new AWSXRayIdGenerator(),
}

// enable debug/logging of otel actions
const { DiagConsoleLogger, DiagLogLevel, diag, propagation, context } = require('@opentelemetry/api');
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);

// The function which init and auto instruments otel for node js
async function nodeSDKBuilder() {
    const sdk = new opentelemetry.NodeSDK({
        textMapPropagator: new CompositePropagator({
            propagators: [
            //   new AWSXRayPropagator(),
              new W3CTraceContextPropagator(),
            //   new B3Propagator(),
            //   new B3Propagator({ injectEncoding: B3InjectEncoding.MULTI_HEADER }),
            ],
          }),
            // new AWSXRayPropagator(),
        instrumentations: [
            getNodeAutoInstrumentations({
                "@opentelemetry/instrumentation-fs": { enabled: false },
                "@opentelemetry/instrumentation-grpc": { enabled: false },
                '@opentelemetry/instrumentation-aws-sdk': { suppressInternalInstrumentation: true },
                '@opentelemetry/instrumentation-aws-lambda': {
                    disableAwsContextPropagation: true,
                    eventContextExtractor: (event, eventContext) => {
                        console.log("eventContext.clientContext", eventContext.clientContext)
                        console.log("event.headers", event.headers)
                        console.log("event.Records[0].Sns.MessageAttributes", event.Records[0].Sns.MessageAttributes)
                        const contextToReturn = propagation.extract(context.active(), event.Records[0].Sns.MessageAttributes, {
                            keys(carrier) {
                                return Object.keys(carrier);
                            },
                            get(carrier, key) {
                                return carrier[key]?.Value;
                            },
                        });

                        console.log("getNodeAutoInstrumentations context", {context: contextToReturn, value: contextToReturn.getValue()})
                        return contextToReturn;
                    },
                }
            })
        ],
        resource: _resource,
        spanProcessor: _spanProcessor,
        traceExporter: _traceExporter,
    });
    sdk.configureTracerProvider(_tracerConfig, _spanProcessor);

    // this enables the API to record telemetry
    await sdk.start();
    // gracefully shut down the SDK on process exit
    process.on('SIGTERM', () => {
        console.log("termination")
    sdk.shutdown()
      .then(() => console.log('Tracing and Metrics terminated'))
      .catch((error) => console.log('Error terminating tracing and metrics', error))
      .finally(() => process.exit(0));
    });
}

nodeSDKBuilder(); // run otel auto instrumentation script/function
exports._spanProcessor= _spanProcessor ;
