import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Box, Button, Typography, CircularProgress } from '@mui/material';
import { Chessboard } from 'react-chessboard';

const Puzzle = () => {
  const [puzzle, setPuzzle] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchPuzzle = async () => {
    setLoading(true);
    setError(null);

    const options = {
      method: 'GET',
      url: 'https://chess-puzzles.p.rapidapi.com/',
      params: {
        themes: '["middlegame","advantage"]',
        rating: '1500',
        themesType: 'ALL',
        playerMoves: '4',
        count: '1', // Adjusting count to 1 to fetch a single puzzle
      },
      headers: {
        'X-RapidAPI-Key': '', // Replace with your actual RapidAPI key
        'X-RapidAPI-Host': 'chess-puzzles.p.rapidapi.com'
      }
    };

    try {
        const response = await axios.request(options);
        console.log('API response:', response.data); // Log the API response to the console
  
        if (response.data.puzzles && response.data.puzzles.length > 0) {
          setPuzzle(response.data.puzzles[0]);
        } else {
          setError('No puzzles found.');
        }
      } catch (err) {
        if (err.response) {
          console.error('Error fetching puzzle:', err.response);
          if (err.response.status === 429) {
            setError('Rate limit exceeded. Please try again later.');
          } else if (err.response.status === 403) {
            setError('You are not subscribed to this API.');
          } else {
            setError(`Error fetching puzzle: ${err.response.statusText}`);
          }
        } else if (err.request) {
          console.error('Error fetching puzzle:', err.request);
          setError('No response from server. Please check your network connection.');
        } else {
          console.error('Error:', err.message);
          setError('An error occurred. Please try again.');
        }
      } finally {
        setLoading(false);
      }
    };
  
    useEffect(() => {
      fetchPuzzle();
    }, []);
  
    if (loading) {
      return (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
          <CircularProgress />
        </Box>
      );
    }
  
    if (error) {
      return (
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Typography variant="h5" color="error">
            {error}
          </Typography>
          <Button variant="contained" color="primary" onClick={fetchPuzzle} sx={{ mt: 2 }}>
            Retry
          </Button>
        </Box>
      );
    }
  
    return (
      <Box sx={{ textAlign: 'center', mt: 4 }}>
        <Typography variant="h4" gutterBottom>
          Solve the Puzzle
        </Typography>
        {puzzle && <Chessboard position={puzzle.fen} />}
        
      </Box>
    );
  };
  
  export default Puzzle;
