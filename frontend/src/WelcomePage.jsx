import React from 'react';
import { Box, Button, Typography } from '@mui/material';
import { useNavigate } from 'react-router-dom';

const WelcomePage = () => {
  const navigate = useNavigate();

  return (
    <Box sx={{ textAlign: 'center', mt: 4 }}>
      <Typography variant="h3" gutterBottom>
        Welcome to Chesscom!
      </Typography>
      <Button
        variant="contained"
        color="primary"
        sx={{ m: 2 }}
        onClick={() => navigate('/game')}
      >
        Play Game
      </Button>
      <Button
        variant="contained"
        color="secondary"
        sx={{ m: 2 }}
        onClick={() => navigate('/learn')}
      >
        Learn Chess
      </Button>
      <Button
        variant="contained"
        color="success"
        sx={{ m: 2 }}
        onClick={() => navigate('/puzzle')}
      >
        Solve Puzzles AND LEARN chess
      </Button>
    </Box>
  );
};

export default WelcomePage;
