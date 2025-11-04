// ChessTutorial.jsx
import { useEffect, useState } from 'react';
import { Chessboard } from 'react-chessboard';
import { Chess } from 'chess.js';
import Shepherd from 'shepherd.js';
import 'shepherd.js/dist/css/shepherd.css';
import { Box, Button, Typography } from '@mui/material';

const ChessTutorial = () => {
  const [chess] = useState(new Chess());
  const [fen, setFen] = useState('');
  const [highlightSquares, setHighlightSquares] = useState({});
  const [tour, setTour] = useState(null);

  const getHighlightedSquares = (piece) => {
    const moves = chess.moves({ verbose: true });
    console.log("Moves for", piece, ":", moves);
  
    const newHighlights = {};
  
    moves.forEach(move => {
      if (move.piece === piece) {
        newHighlights[move.to] = { backgroundColor: 'rgba(0, 255, 0, 0.4)' };
      }
    });
  
    console.log("New Highlights:", newHighlights);
    return newHighlights;
  };

  const setupBoardForPiece = (piece) => {
    let setupFen = '8/8/8/8/8/8/8/8 w - - 0 1'; // Empty board
    chess.clear();

    switch (piece) {
      case 'king':
        setupFen = '8/8/8/8/4K3/8/8/4k3 w - - 0 1';
        break;
      case 'queen':
        setupFen = '8/8/8/8/4Q3/8/7k/K7 w - - 0 1'; // White queen on e4, black queen on h6, kings in corners
        break;
      case 'rook':
        setupFen = '8/8/8/8/4R3/8/4K3/4k3 w - - 0 1';
        break;
      case 'bishop':
        setupFen = '8/8/8/8/4B3/8/4K3/4k3 w - - 0 1';
        break;
      case 'knight':
        setupFen = '8/8/8/8/4N3/8/4K3/4k3 w - - 0 1';
        break;
      case 'pawn':
        setupFen = '8/8/8/8/4P3/8/4K3/4k3 w - - 0 1';
        break;
      default:
        setupFen = '8/8/8/8/8/8/4K3/4k3 w - - 0 1';
    }

    chess.load(setupFen);
    setFen(chess.fen());
    setHighlightSquares({});
  };

  useEffect(() => {
    const newTour = new Shepherd.Tour({
      defaultStepOptions: {
        classes: 'shepherd-theme-arrows',
        scrollTo: true,
      },
    });

    newTour.addStep({
      id: 'welcome',
      title: 'Welcome to the Chess Tutorial',
      text: 'We will guide you through the basic movements of each chess piece.',
      buttons: [
        {
          text: 'Next',
          action: newTour.next,
        },
      ],
    });

    newTour.addStep({
      id: 'board',
      title: 'Chessboard',
      text: 'This is the chessboard. Pieces move in different ways. Let\'s start with the king.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('king');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'king',
      title: 'King',
      text: 'The king moves one square in any direction.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
            text: 'Show Move',
            action: () => {
              const highlights = getHighlightedSquares('king');
              console.log('Highlight squares:', highlights);
              setHighlightSquares(highlights);
            },
          },
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('queen');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'queen',
      title: 'Queen',
      text: 'The queen moves any number of squares along a row, column, or diagonal.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Show Move',
          action: () => {
            setHighlightSquares(getHighlightedSquares('queen'));
          },
        },
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('rook');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'rook',
      title: 'Rook',
      text: 'The rook moves any number of squares along a row or column.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Show Move',
          action: () => {
            setHighlightSquares(getHighlightedSquares('rook'));
          },
        },
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('bishop');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'bishop',
      title: 'Bishop',
      text: 'The bishop moves any number of squares along a diagonal.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Show Move',
          action: () => {
            setHighlightSquares(getHighlightedSquares('bishop'));
          },
        },
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('knight');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'knight',
      title: 'Knight',
      text: 'The knight moves in an "L" shape: two squares in one direction and then one square perpendicular.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Show Move',
          action: () => {
            setHighlightSquares(getHighlightedSquares('knight'));
          },
        },
        {
          text: 'Next',
          action: () => {
            setupBoardForPiece('pawn');
            newTour.next();
          },
        },
      ],
    });

    newTour.addStep({
      id: 'pawn',
      title: 'Pawn',
      text: 'Pawns move forward one square, but capture diagonally. On their first move, they can move two squares.',
      attachTo: {
        element: '#chessboard',
        on: 'top',
      },
      buttons: [
        {
          text: 'Show Move',
          action: () => {
            setHighlightSquares(getHighlightedSquares('pawn'));
          },
        },
        {
          text: 'Finish',
          action: newTour.complete,
        },
      ],
    });

    setTour(newTour);
  }, [chess]);

  return (
    <Box>
      <Typography variant="h4">Chess Tutorial</Typography>
      <Chessboard
        id="chessboard"
        position={fen}
        customSquareStyles={highlightSquares}
      />
      <Button onClick={() => tour.start()}>Start Tutorial</Button>
    </Box>
  );
};

export default ChessTutorial;
