FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY .env* ./

COPY . .

EXPOSE 5000

CMD ["node", "server.js"] 
