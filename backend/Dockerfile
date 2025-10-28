# Frontend Dockerfile (place this in your React project directory)
# frontend/Dockerfile
# Backend Dockerfile (place this in your WebSocket server directory)
# backend/Dockerfile

FROM node:18
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
EXPOSE 8181
CMD ["node", "app.js"]

