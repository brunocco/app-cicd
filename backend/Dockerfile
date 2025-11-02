FROM node:18-bullseye

WORKDIR /app

COPY package*.json ./

RUN apt-get update && apt-get install -y python3 g++ make \
    && npm install --build-from-source

COPY . .

EXPOSE 3000

# Instala o wait-for-it
RUN apt-get install -y wget && \
    wget -O wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
    chmod +x wait-for-it.sh

# Usa o wait-for-it para esperar o Postgres
CMD ["./wait-for-it.sh", "db:5432", "--", "node", "app.js"]
