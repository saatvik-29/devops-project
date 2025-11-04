
import {
  Card,
  CardContent,
  List,
  ListItem,
  ListItemText,
  ListSubheader,
  Stack,
  Typography,
  Box,
} from "@mui/material";
import { useState, useMemo, useCallback, useEffect } from "react";
import { Chessboard } from "react-chessboard";
import { Chess } from "chess.js";
import CustomDialog from "./components/CustomDialog.jsx";
import socket from "./socket.jsx";

function Game({ players, room, orientation, cleanup }) {
  const [chess] = useState(new Chess());
  const [fen, setFen] = useState(chess.fen());
  const [over, setOver] = useState("");
  const [gameLog, setGameLog] = useState([]);

  const makeAMove = useCallback(
    (move) => {
      try {
        const result = chess.move(move);
        setFen(chess.fen());
        
        // Log the move
        const moveNotation = chess.history({ verbose: true }).slice(-1)[0].san;
        setGameLog(prevLog => [...prevLog, moveNotation]);

        if (chess.isGameOver()) {
          if (chess.isCheckmate()) {
            setOver(`Checkmate! ${chess.turn() === 'w' ? 'black' : 'white'} wins!`);
          } else if (chess.isDraw()) {
            setOver('Draw');
          } else {
            setOver('Game over');
          }
        }
        
        return result;
      } catch (e) {
        return null;
      }
    },
    [chess]
  );

  // onDrop function
  function onDrop(sourceSquare, targetSquare) {
    if (chess.turn() !== orientation[0]) return false;

    if (players.length < 2) return false;

    const moveData = {
      from: sourceSquare,
      to: targetSquare,
      color: chess.turn(),
      promotion: "q",
    };

    const move = makeAMove(moveData);

    if (move === null) return false;

    socket.emit("move", {
      move,
      room,
    });

    return true;
  }

  useEffect(() => {
    socket.on("move", (move) => {
      makeAMove(move);
    });
  }, [makeAMove]);
  
  // Game component returned jsx
  return (
    <Stack>
      <Card>
        <CardContent>
          <Typography variant="h5">Room ID: {room}</Typography>
        </CardContent>
      </Card>
      <Stack flexDirection="row" sx={{ pt: 2 }}>
        <div className="board" style={{
          maxWidth: 600,
          maxHeight: 600,
          flexGrow: 1,
        }}>
          <Chessboard
            position={fen}
            onPieceDrop={onDrop}
            boardOrientation={orientation}
          />
        </div>
        {players.length > 0 && (
          <Box>
            <List>
              <ListSubheader>Players</ListSubheader>
              {players.map((p) => (
                <ListItem key={p.id}>
                  <ListItemText primary={p.username} />
                </ListItem>
              ))}
            </List>
          </Box>
        )}
      </Stack>
      <Box>
        <List>
          <ListSubheader>Game Log</ListSubheader>
          {gameLog.map((move, index) => (
            <ListItem key={index}>
              <ListItemText primary={move} />
            </ListItem>
          ))}
        </List>
      </Box>
      <CustomDialog // Game Over CustomDialog
        open={Boolean(over)}
        title={over}
        contentText={over}
        handleContinue={() => {
          setOver("");
        }}
      />
    </Stack>
  );
}

export default Game;
