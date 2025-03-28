# Toxic Text Battleship

A Flutter application that combines text toxicity detection with a battleship-style game. The app features a toxicity checker and an interactive game where players discover toxic and non-toxic phrases hidden in a grid.

## Features

### Toxicity Checker
- Real-time text toxicity detection using an AI-powered API
- Adjustable safety threshold for toxicity detection
- Random post fetching from various sources (Reddit, Quotes API)
- Detailed toxicity analysis with percentage scores

### Toxic Text Battleship Game
- 8x8 grid with hidden phrases
- 5 "ships" containing toxic phrases:
  - 1 ship of length 4 (horizontal)
  - 2 ships of length 3 (horizontal and vertical)
  - 2 ships of length 2 (horizontal and vertical)
- Interactive grid cells that reveal:
  - The hidden phrase
  - Loading state while checking toxicity
  - Toxicity percentage once revealed
- Color-coded results:
  - Red: Toxic phrases (>50% toxicity)
  - Light Blue: Non-toxic phrases (<50% toxicity)
- Game controls:
  - Start Game: Initializes a new game with randomly placed phrases
  - Reveal All: Shows all unrevealed cells
  - New Game: Resets the game and returns to the main view

## Technical Details

- Built with Flutter
- Uses the Hugging Face Space API for toxicity detection
- Implements a battleship-style placement algorithm for toxic phrases
- Responsive design that adapts to different screen sizes

## Setup

1. Ensure you have Flutter installed on your system
2. Clone this repository
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

- `http`: For making API requests
- `dart:convert`: For JSON parsing
- `dart:math`: For random number generation

## API Integration

The app uses the following APIs:
- Hugging Face Space API for toxicity detection
- Reddit API for random posts
- Quotable API for random quotes

## Game Rules

1. Click "Start Game" to begin
2. Tap on grid cells to reveal their content
3. Each cell will show:
   - The hidden phrase
   - A loading spinner while checking toxicity
   - The toxicity percentage once revealed
4. Use the "Reveal All" button to show all remaining cells
5. Start a new game at any time using the "New Game" button

## Contributing

Feel free to submit issues and enhancement requests!
