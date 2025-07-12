import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(
    GameWidget(
      game: TiltMazeGame(),
      overlayBuilderMap: {
        'win': (_, game) => WinOverlay(game: game as TiltMazeGame),
      },
    ),
  );
}

// =========================
// ✅ The Game Class
// =========================

class TiltMazeGame extends FlameGame with HasCollisionDetection {
  late Ball ball;
  late Goal goal;

  double speedX = 0;
  double speedY = 0;

  @override
  Future<void> onLoad() async {
    // Add Ball
    ball = Ball()
      ..size = Vector2.all(30)
      ..position = size / 2;
    add(ball);

    // Add Walls
    add(Wall(
      position: Vector2(200, 300),
      size: Vector2(100, 20),
    ));

    add(Wall(
      position: Vector2(100, 500),
      size: Vector2(20, 100),
    ));

    // Add Goal
    goal = Goal()
      ..size = Vector2.all(40)
      ..position = Vector2(size.x - 60, size.y - 60);
    add(goal);

    // Listen to tilt
    accelerometerEvents.listen((event) {
      speedX += event.x * -10;
      speedY += event.y * 10;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update ball position
    ball.position.add(Vector2(speedX, speedY) * dt);

    // Friction
    speedX *= 0.9;
    speedY *= 0.9;

    // Keep inside screen
    ball.position.clamp(
      Vector2.zero() + ball.size / 2,
      size - ball.size / 2,
    );

    // Win check
    if (ball.toRect().overlaps(goal.toRect())) {
      overlays.add('win');
      pauseEngine();
    }
  }

  void reset() {
    ball.position = size / 2;
    speedX = 0;
    speedY = 0;
    resumeEngine();
    overlays.remove('win');
  }
}

// =========================
// ✅ Ball Component
// =========================

class Ball extends PositionComponent with CollisionCallbacks {
  Ball() {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.blue;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );
  }
}

// =========================
// ✅ Wall Component
// =========================

class Wall extends PositionComponent with CollisionCallbacks {
  Wall({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.black;
    canvas.drawRect(size.toRect(), paint);
  }
}

// =========================
// ✅ Goal Component
// =========================

class Goal extends PositionComponent {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.green;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );
  }
}

// =========================
// ✅ Win Overlay
// =========================

class WinOverlay extends StatelessWidget {
  final TiltMazeGame game;

  const WinOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 You Win!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            game.reset();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}
