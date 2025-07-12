import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

void main() => runApp(TiltMazeApp());

class TiltMazeApp extends StatefulWidget {
  @override
  _TiltMazeAppState createState() => _TiltMazeAppState();
}

class _TiltMazeAppState extends State<TiltMazeApp> {
  double posX = 0;
  double posY = 0;

  double speedX = 0;
  double speedY = 0;

  final double ballSize = 30;
  final double areaWidth = 400;
  final double areaHeight = 600;

  final double goalSize = 40;

  StreamSubscription? accel;

  @override
  void initState() {
    super.initState();

    accel = accelerometerEvents.listen((event) {
      setState(() {
        // Control sensitivity
        speedX += event.x * -0.2; // invert X for natural feel
        speedY += event.y * 0.2;

        // Apply speed
        posX += speedX;
        posY += speedY;

        // Friction
        speedX *= 0.95;
        speedY *= 0.95;

        // Keep inside box
        posX = posX.clamp(-areaWidth / 2 + ballSize / 2, areaWidth / 2 - ballSize / 2);
        posY = posY.clamp(-areaHeight / 2 + ballSize / 2, areaHeight / 2 - ballSize / 2);

        // Check goal
        checkWin();

        // Check simple wall collision
        checkWallCollision();
      });
    });
  }

  void checkWin() {
    // Goal at bottom right corner
    double goalX = areaWidth / 2 - 60;
    double goalY = areaHeight / 2 - 60;

    double dx = posX - goalX;
    double dy = posY - goalY;

    if (dx.abs() < goalSize / 2 && dy.abs() < goalSize / 2) {
      showWinDialog();
    }
  }

  void showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('You Win! 🎉'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: Text('Play Again'),
          )
        ],
      ),
    );
  }

  void resetGame() {
    posX = 0;
    posY = 0;
    speedX = 0;
    speedY = 0;
  }

  void checkWallCollision() {
    // Example wall: horizontal wall in middle
    // Wall area: -50 < posX < 50, -10 < posY < 10

    if (posX > -50 && posX < 50 && posY > -10 && posY < 10) {
      // Simple bounce back
      if (posY > 0) {
        posY = 10; // push outside
      } else {
        posY = -10;
      }
      speedY = -speedY * 0.5;
    }
  }

  @override
  void dispose() {
    accel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Tilt Maze Game')),
        body: Center(
          child: Container(
            width: areaWidth,
            height: areaHeight,
            color: Colors.grey.shade300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ball
                Positioned(
                  left: areaWidth / 2 + posX - ballSize / 2,
                  top: areaHeight / 2 + posY - ballSize / 2,
                  child: Container(
                    width: ballSize,
                    height: ballSize,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Goal
                Positioned(
                  left: areaWidth - 60 - goalSize / 2,
                  top: areaHeight - 60 - goalSize / 2,
                  child: Container(
                    width: goalSize,
                    height: goalSize,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Wall
                Positioned(
                  left: areaWidth / 2 - 50,
                  top: areaHeight / 2 - 10,
                  child: Container(
                    width: 100,
                    height: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
