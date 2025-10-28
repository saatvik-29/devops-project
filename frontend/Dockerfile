FROM node:18

# Set working directory
WORKDIR /app

# Install serve for production static file serving
RUN npm install -g serve

# Copy package files and install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy all files
COPY . .

# Build the app
RUN npm run build

# Expose port
EXPOSE 5173

# Serve the app
CMD ["serve", "-s", "dist", "-l", "5173"]


