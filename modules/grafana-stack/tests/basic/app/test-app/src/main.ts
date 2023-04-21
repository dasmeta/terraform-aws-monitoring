import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  // require('./tracing')
  const app = await NestFactory.create(AppModule);

  if (process.env.GLOBAL_ROUTE_PREFIX) {
    app.setGlobalPrefix(process.env.GLOBAL_ROUTE_PREFIX);
  }

  await app.listen(3000);
}
bootstrap();
