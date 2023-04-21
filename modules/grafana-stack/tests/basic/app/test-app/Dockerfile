FROM node:18-alpine

# ENV TERM xterm-256color

# update/get apk packages list/cache
# RUN apk update

WORKDIR /app
COPY . .

# remove apk cache
# RUN rm -rf /var/cache/apk/*

RUN yarn
RUN yarn global add typescript ts-node
RUN yarn build

EXPOSE 3000

# ENTRYPOINT ["/usr/bin/dumb-init","--"]

CMD [ "yarn", "start" ]
