const { CompositePropagator, W3CTraceContextPropagator } = require('@opentelemetry/core');
const { B3InjectEncoding, B3Propagator } = require('@opentelemetry/propagator-b3');
const opentelemetry = require("@opentelemetry/sdk-node");
const { Resource } = require("@opentelemetry/resources");
const { SemanticResourceAttributes } = require("@opentelemetry/semantic-conventions");
const { BatchSpanProcessor} = require('@opentelemetry/sdk-trace-base');
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
const _tracerConfig = {
    idGenerator: new AWSXRayIdGenerator(),
}

// enable debug/logging of otel actions
const { DiagConsoleLogger, DiagLogLevel, diag } = require('@opentelemetry/api');
diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.DEBUG);

// The function which init and auto instruments otel for node js
async function nodeSDKBuilder() {
    const sdk = new opentelemetry.NodeSDK({
        textMapPropagator: new CompositePropagator({
            propagators: [
              new AWSXRayPropagator(),
            //   new W3CTraceContextPropagator(),
            //   new B3Propagator(),
            //   new B3Propagator({ injectEncoding: B3InjectEncoding.MULTI_HEADER }),
            ],
          }),
            // new AWSXRayPropagator(),
        instrumentations: [
            getNodeAutoInstrumentations({
                "@opentelemetry/instrumentation-fs": { enabled: false },
                '@opentelemetry/instrumentation-aws-sdk': {suppressInternalInstrumentation: true}
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
    sdk.shutdown()
      .then(() => console.log('Tracing and Metrics terminated'))
      .catch((error) => console.log('Error terminating tracing and metrics', error))
      .finally(() => process.exit(0));
    });
}

nodeSDKBuilder(); // run otel auto instrumentation script/function