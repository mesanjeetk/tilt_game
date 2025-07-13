import 'dart:convert';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flame/components.dart'; // ✅ for Anchor

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final levels = await loadLevels();
  runApp(
    GameWidget(
      game: TiltMazePhysicsGame(levels),
      overlayBuilderMap: {
        'win': (_, game) => WinOverlay(game: game as TiltMazePhysicsGame),
      },
    ),
  );
}

Future<List<LevelData>> loadLevels() async {
  final String data = await rootBundle.loadString('assets/levels.json');
  final jsonResult = jsonDecode(data);
  return (jsonResult['levels'] as List)
      .map((e) => LevelData.fromJson(e))
      .toList();
}

class LevelData {
  final Vector2 goal;
  final List<WallData> walls;

  LevelData({required this.goal, required this.walls});

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      goal: Vector2(json['goal']['x'].toDouble(), json['goal']['y'].toDouble()),
      walls: (json['walls'] as List)
          .map((w) => WallData.fromJson(w))
          .toList(),
    );
  }
}

class WallData {
  final double x, y, w, h;

  WallData({required this.x, required this.y, required this.w, required this.h});

  factory WallData.fromJson(Map<String, dynamic> json) {
    return WallData(
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      w: json['w'].toDouble(),
      h: json['h'].toDouble(),
    );
  }
}

class TiltMazePhysicsGame extends Forge2DGame with ContactCallbacks {
  TiltMazePhysicsGame(this.levels)
      : super(
          gravity: Vector2.zero(),
          zoom: 30, // adjust for scale
        );

  final List<LevelData> levels;
  int currentLevelIndex = 0;

  late Ball ball;
  Goal? goal;

  Vector2 lastForce = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFFE0E0E0);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center; // ✅ works fine
    await loadLevel();

    accelerometerEvents.listen((event) {
      lastForce = Vector2(-event.x, event.y) * 5;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    ball.body.applyLinearImpulse(lastForce * dt);
  }

  Future<void> loadLevel() async {
    children.whereType<BodyComponent>().forEach((b) => b.removeFromParent());
    final level = levels[currentLevelIndex];

    ball = Ball(this);
    add(ball);

    goal = Goal(this, level.goal);
    add(goal!);

    for (var w in level.walls) {
      add(Wall(this, Vector2(w.x, w.y), Vector2(w.w, w.h)));
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    final a = contact.fixtureA.body.userData;
    final b = contact.fixtureB.body.userData;

    if ((a is Ball && b is Goal) || (b is Ball && a is Goal)) {
      overlays.add('win');
      pauseEngine();
    }
  }

  void nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
    } else {
      currentLevelIndex = 0;
    }
    loadLevel();
    resumeEngine();
    overlays.remove('win');
  }
}

class Ball extends BodyComponent {
  final TiltMazePhysicsGame game;

  Ball(this.game);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.3;
    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..restitution = 0.8;
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = Vector2.zero();
    final body = world.createBody(bodyDef)..createFixture(fixtureDef);
    body.userData = this;
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blue;
    canvas.drawCircle(
      Offset.zero,
      0.3 * game.zoom,
      paint,
    );
  }
}

class Wall extends BodyComponent {
  final TiltMazePhysicsGame game;
  final Vector2 pos, size;

  Wall(this.game, this.pos, this.size);

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(size.x, size.y);
    final fixtureDef = FixtureDef(shape);
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = pos;
    final body = world.createBody(bodyDef)..createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.grey.shade800;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 2 * game.zoom,
        height: size.y * 2 * game.zoom,
      ),
      paint,
    );
  }
}

class Goal extends BodyComponent {
  final TiltMazePhysicsGame game;
  final Vector2 pos;
  double angle = 0;

  Goal(this.game, this.pos);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.4;
    final fixtureDef = FixtureDef(shape)..isSensor = true;
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = pos;
    final body = world.createBody(bodyDef)..createFixture(fixtureDef);
    body.userData = this;
    return body;
  }

  @override
  void render(Canvas canvas) {
    angle += 0.05;
    canvas.save();
    canvas.rotate(angle);
    final paint = Paint()..color = Colors.green;
    canvas.drawCircle(
      Offset.zero,
      0.4 * game.zoom,
      paint,
    );
    canvas.restore();
  }
}

class WinOverlay extends StatelessWidget {
  final TiltMazePhysicsGame game;

  const WinOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isLast = game.currentLevelIndex == game.levels.length - 1;
    return AlertDialog(
      title: Text(isLast ? '🏆 All Levels Done!' : '🎉 Level Complete!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            game.nextLevel();
          },
          child: Text(isLast ? 'Restart' : 'Next Level'),
        ),
      ],
    );
  }
}
