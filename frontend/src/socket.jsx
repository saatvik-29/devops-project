import { io } from "socket.io-client";

// Dynamically determine the WebSocket URL based on the current window location
const getSocketUrl = () => {
  // Get the hostname from the current window location
  const host = window.location.hostname;
  
  // Use secure WebSocket if page is loaded over HTTPS
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  
  // Use port 8080 for the backend WebSocket
  return `${protocol}//${host}:8181`;
};

// Initialize socket connection
const socket = io(getSocketUrl(), {
  reconnectionAttempts: 5,
  reconnectionDelay: 1000,
  autoConnect: true,
});

// Add basic logging
socket.on('connect', () => {
  console.log('Socket connected successfully');
});

socket.on('connect_error', (error) => {
  console.error('Socket connection error:', error);
});

export default socket;