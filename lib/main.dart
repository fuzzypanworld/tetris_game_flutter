import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    home: PlayScreen(),
  ));
}

class PlayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tetris Game'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return GameWidget(
                game: TetrisGame(
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                ),
              );
            },
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => TetrisGame.instance?.moveTetromino(-1, 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                  child: Icon(Icons.arrow_left, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () => TetrisGame.instance?.rotateTetromino(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                  child: Icon(Icons.rotate_right, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () => TetrisGame.instance?.moveTetromino(1, 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                  child: Icon(Icons.arrow_right, color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () => TetrisGame.instance?.moveTetromino(0, 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                  child: Icon(Icons.arrow_downward, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Score: ${TetrisGame.instance?.score ?? 0}',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TetrisGame extends FlameGame {
  static TetrisGame? instance;
  static const int rows = 20;
  static const int cols = 10;
  final List<List<Color?>> board = List.generate(rows, (_) => List.filled(cols, null));
  Tetromino? currentTetromino;
  Timer? fallTimer;
  int score = 0;
  bool isGameOver = false;
  double screenWidth;
  double screenHeight;
  late double blockSize;

  TetrisGame({required this.screenWidth, required this.screenHeight}) {
    instance = this;
    blockSize = min(screenWidth / cols, screenHeight / rows);
  }

  @override
  Future<void> onLoad() async {
    startNewTetromino();
    startFalling();
  }

  void startNewTetromino() {
    currentTetromino = Tetromino.random(cols ~/ 2);
    if (!canPlace(currentTetromino!)) {
      isGameOver = true;
      fallTimer?.cancel();
    }
  }

  void startFalling() {
    fallTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      moveTetromino(0, 1);
    });
  }

  void moveTetromino(int dx, int dy) {
    if (currentTetromino == null) return;
    Tetromino moved = currentTetromino!.moved(dx, dy);
    if (canPlace(moved)) {
      currentTetromino = moved;
    } else if (dy > 0) {
      placeTetromino();
      clearRows();
      startNewTetromino();
    }
  }

  void rotateTetromino() {
    if (currentTetromino == null) return;
    Tetromino rotated = currentTetromino!.rotated();
    if (canPlace(rotated)) {
      currentTetromino = rotated;
    }
  }

  bool canPlace(Tetromino tetromino) {
    for (Point<int> block in tetromino.blocks) {
      int x = block.x;
      int y = block.y;
      if (x < 0 || x >= cols || y >= rows || (y >= 0 && board[y][x] != null)) {
        return false;
      }
    }
    return true;
  }

  void placeTetromino() {
    if (currentTetromino == null) return;
    for (Point<int> block in currentTetromino!.blocks) {
      if (block.y >= 0) {
        board[block.y][block.x] = currentTetromino!.color;
      }
    }
  }

  void clearRows() {
    for (int y = 0; y < rows; y++) {
      if (board[y].every((cell) => cell != null)) {
        for (int j = y; j > 0; j--) {
          board[j] = List.from(board[j - 1]);
        }
        board[0] = List.filled(cols, null);
        score += 100;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (isGameOver) {
      final textStyle = TextStyle(color: Colors.red, fontSize: 32);
      final textSpan = TextSpan(text: 'Game Over', style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(screenWidth / 2 - textPainter.width / 2, screenHeight / 2 - textPainter.height / 2));
      return;
    }

    Paint paint = Paint();
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (board[y][x] != null) {
          paint.color = board[y][x]!;
          canvas.drawRect(Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize), paint);
        }
      }
    }

    if (currentTetromino != null) {
      paint.color = currentTetromino!.color;
      for (Point<int> block in currentTetromino!.blocks) {
        if (block.y >= 0) {
          canvas.drawRect(Rect.fromLTWH(block.x * blockSize, block.y * blockSize, blockSize, blockSize), paint);
        }
      }
    }
  }
}

class Tetromino {
  final List<Point<int>> blocks;
  final Color color;

  Tetromino(this.blocks, this.color);

  factory Tetromino.random(int startX) {
    final shapes = [
      [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)], // O
      [Point(0, 0), Point(-1, 0), Point(1, 0), Point(0, 1)], // T
      [Point(0, 0), Point(0, -1), Point(0, 1), Point(1, 1)], // L
      [Point(0, 0), Point(0, -1), Point(0, 1), Point(-1, 1)], // J
      [Point(0, 0), Point(-1, 0), Point(0, 1), Point(1, 1)], // S
      [Point(0, 0), Point(1, 0), Point(0, 1), Point(-1, 1)], // Z
      [Point(0, 0), Point(0, -1), Point(0, 1), Point(0, 2)], // I
    ];
    final randomIndex = Random().nextInt(shapes.length);
    final colorList = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.orange, Colors.purple, Colors.cyan];
    final color = colorList[randomIndex];
    return Tetromino(shapes[randomIndex].map((p) => Point(p.x + startX, p.y)).toList(), color);
  }

  Tetromino moved(int dx, int dy) {
    return Tetromino(blocks.map((b) => Point(b.x + dx, b.y + dy)).toList(), color);
  }

  Tetromino rotated() {
    int centerX = blocks[0].x;
    int centerY = blocks[0].y;
    return Tetromino(
      blocks.map((b) => Point(centerX - (b.y - centerY), centerY + (b.x - centerX))).toList(),
      color,
    );
  }
}
