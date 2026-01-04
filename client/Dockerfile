# Build stage
FROM node:18-alpine AS build
WORKDIR /app

# allow setting API url at build time
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Install deps and build
COPY package*.json ./
RUN npm install
COPY . .
# Workaround for OpenSSL incompatibility on Node 17/18 with older react-scripts
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build

# Production stage
FROM nginx:stable-alpine
# replace default nginx conf with our proxy config so /api is forwarded to backend
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
