

import { useEffect, useState, useCallback } from 'react';
import { Container, AppBar, Toolbar, Typography, Button, TextField, CssBaseline, ThemeProvider, createTheme } from '@mui/material';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Game from './Game.jsx';
import InitGame from './Initgame.jsx';
import CustomDialog from './components/CustomDialog.jsx';
import WelcomePage from './WelcomePage.jsx';
import ChessTutorial from './ChessTutorial.jsx';
import Puzzle from './Puzzle.jsx';
import socket from './socket.jsx';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
  typography: {
    h6: {
      flexGrow: 1,
    },
  },
});

function GameContainer() {
  const [username, setUsername] = useState('');
  const [usernameSubmitted, setUsernameSubmitted] = useState(false);
  const [room, setRoom] = useState('');
  const [orientation, setOrientation] = useState('');
  const [players, setPlayers] = useState([]);

  const cleanup = useCallback(() => {
    setRoom('');
    setOrientation('');
    setPlayers([]);
  }, []);

  useEffect(() => {
    socket.on('opponentJoined', (roomData) => {
      console.log('roomData', roomData);
      setPlayers(roomData.players);
    });
  }, []);

  return (
    <Container maxWidth="md" sx={{ mt: 4 }}>
      <CustomDialog
        open={!usernameSubmitted}
        handleClose={() => setUsernameSubmitted(true)}
        title="Pick a username"
        contentText="Please select a username"
        handleContinue={() => {
          if (!username) return;
          socket.emit('username', username);
          setUsernameSubmitted(true);
        }}
      >
        <TextField
          autoFocus
          margin="dense"
          id="username"
          label="Username"
          name="username"
          value={username}
          required
          onChange={(e) => setUsername(e.target.value)}
          type="text"
          fullWidth
          variant="standard"
        />
      </CustomDialog>
      {room ? (
        <Game
          room={room}
          orientation={orientation}
          username={username}
          players={players}
          cleanup={cleanup}
        />
      ) : (
        <InitGame
          setRoom={setRoom}
          setOrientation={setOrientation}
          setPlayers={setPlayers}
        />
      )}
    </Container>
  );
}

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <AppBar position="static">
          <Toolbar>
            <Typography variant="h6" component="div">
              Chess App
            </Typography>
            <Button color="inherit" component={Link} to="/">
              Home
            </Button>
            <Button color="inherit" component={Link} to="/game">
              Game
            </Button>
            <Button color="inherit" component={Link} to="/learn">
              Learn
            </Button>
            <Button color="inherit" component={Link} to="/puzzle">
              Puzzle
            </Button>
          </Toolbar>
        </AppBar>
        <Container>
          <Routes>
            <Route path="/" element={<WelcomePage />} />
            <Route path="/game" element={<GameContainer />} />
            <Route path="/learn" element={<ChessTutorial />} />
            <Route path="/puzzle" element={<Puzzle />} />
          </Routes>
        </Container>
      </Router>
    </ThemeProvider>
  );
}
