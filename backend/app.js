import express from 'express';
import { Server } from 'socket.io';
import { v4 as uuidV4 } from 'uuid';
import http from 'http';

const app = express(); // Initialize Express

// Allow requests from any origin (important for EC2)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

const server = http.createServer(app);

// Set port from environment variable or default to 8080
const port = process.env.PORT || 8181;

// Bind server to all network interfaces (required for EC2)
const io = new Server(server, {
  cors: { origin: '*' },
});

const rooms = new Map();

io.on('connection', (socket) => {
  console.log(`${socket.id} connected`);

  socket.on('username', (username) => {
    console.log('Username:', username);
    socket.data.username = username;
  });

  socket.on('createRoom', async (callback) => {
    const roomId = uuidV4();
    await socket.join(roomId);

    rooms.set(roomId, {
      roomId,
      players: [{ id: socket.id, username: socket.data?.username }],
    });

    callback(roomId);
  });

  socket.on('joinRoom', async (args, callback) => {
    const room = rooms.get(args.roomId);
    let error, message;

    if (!room) {
      error = true;
      message = 'Room does not exist';
    } else if (room.players.length === 0) {
      error = true;
      message = 'Room is empty';
    } else if (room.players.length >= 2) {
      error = true;
      message = 'Room is full';
    }

    if (error) {
      return callback && callback({ error, message });
    }

    await socket.join(args.roomId);
    
    const updatedRoom = {
      ...room,
      players: [...room.players, { id: socket.id, username: socket.data?.username }],
    };

    rooms.set(args.roomId, updatedRoom);
    callback(updatedRoom);
    
    socket.to(args.roomId).emit('opponentJoined', updatedRoom);
  });

  socket.on('move', (data) => {
    socket.to(data.room).emit('move', data.move);
  });

  socket.on('disconnect', () => {
    console.log(`${socket.id} disconnected`);
  });
});

// Listen on all available interfaces (important for EC2)
server.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
