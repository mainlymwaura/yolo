FROM node:18-alpine

WORKDIR /app

# Set production environment and use npm ci for reproducible installs
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 5000

CMD ["node", "server.js"]

