FROM node:20-alpine

WORKDIR /app

COPY . .

WORKDIR /app/devops-front
RUN npm install

RUN npm run build

EXPOSE 4173

CMD ["npm", "run", "preview"]