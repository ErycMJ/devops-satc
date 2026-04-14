FROM node:20-alpine

RUN apk update && apk upgrade

WORKDIR /app

COPY devops-front/package*.json ./devops-front/

WORKDIR /app/devops-front
RUN npm install

COPY . .

RUN npm run build

EXPOSE 4173

CMD ["npm", "run", "preview"]