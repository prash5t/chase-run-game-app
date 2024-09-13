import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:async';
import 'dart:math' as math;

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late IO.Socket socket;
  Map<String, PlayerData> players = {};
  String? chaser;
  String? myId;
  bool showAnimation = false;
  String animationText = '';
  bool isGameStarting = false;
  int countdown = 3;
  final joystickRadius = 100.0;
  final joystickAreaHeight = 250.0;
  late Size gameViewSize;
  bool showCountdown = false;
  Color countdownColor = Colors.white;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  void connectToServer() {
    socket = IO.io('http://10.10.10.149:5001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Connected to server');
      myId = socket.id;
    });

    socket.on('updatePlayers', (data) {
      setState(() {
        players = Map<String, PlayerData>.from(
            data['players'].map((key, value) => MapEntry(
                key,
                PlayerData(
                  position:
                      Offset(value['x'].toDouble(), value['y'].toDouble()),
                  isChaser: value['is_chaser'],
                ))));

        String? newChaser = data['chaser'];
        if (newChaser != chaser) {
          if (newChaser == myId) {
            showAnimationWithText('You are now the chaser!');
          } else if (chaser == myId) {
            showAnimationWithText('You are now a runner!');
          }
          chaser = newChaser;
          startCountdown();
        }
      });
    });

    socket.on('gameStart', (_) {
      startCountdown();
    });
  }

  void showAnimationWithText(String text) {
    setState(() {
      showAnimation = true;
      animationText = text;
      showCountdown = false; // Ensure countdown is not shown simultaneously
    });
    Timer(Duration(seconds: 2), () {
      setState(() {
        showAnimation = false;
      });
    });
  }

  void startCountdown() {
    setState(() {
      isGameStarting = true;
      countdown = 3;
      showCountdown = true;
      showAnimation = false; // Ensure role message is not shown simultaneously
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 1) {
          countdown--;
          countdownColor = countdown == 3
              ? Colors.red
              : countdown == 2
                  ? Colors.yellow
                  : Colors.green;
        } else {
          isGameStarting = false;
          showCountdown = false;
          timer.cancel();
          spawnPlayersRandomly();
        }
      });
    });
  }

  void spawnPlayersRandomly() {
    if (myId != null) {
      final random = math.Random();
      final newX = random.nextDouble() * (gameViewSize.width - 20) + 10;
      final newY = random.nextDouble() * (gameViewSize.height - 20) + 10;
      socket.emit('move', {'x': newX, 'y': newY});
    }
  }

  void movePlayer(Offset direction) {
    if (myId != null && players.containsKey(myId)) {
      final currentPosition = players[myId]!.position;
      final newPosition = Offset(
        (currentPosition.dx + direction.dx * 5)
            .clamp(10, gameViewSize.width - 10),
        (currentPosition.dy + direction.dy * 5)
            .clamp(10, gameViewSize.height - 10),
      );
      socket.emit('move', {'x': newPosition.dx, 'y': newPosition.dy});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    gameViewSize = Size(
      screenSize.width,
      screenSize.height - joystickAreaHeight - safeAreaTop - safeAreaBottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: gameViewSize.width,
                height: gameViewSize.height,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: FootballFieldPainter(),
                      size: gameViewSize,
                    ),
                    if (players.isNotEmpty)
                      CustomPaint(
                        painter: GamePainter(players[myId]!, players),
                        size: gameViewSize,
                      ),
                    if (showAnimation)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            animationText,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (showCountdown)
                      Center(
                        child: Text(
                          countdown.toString(),
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.bold,
                            color: countdownColor,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(5.0, 5.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              height: joystickAreaHeight,
              color: Colors.grey[300],
              child: Center(
                child: JoystickArea(
                  onDirectionChanged: movePlayer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}

class JoystickArea extends StatelessWidget {
  final Function(Offset) onDirectionChanged;

  const JoystickArea({Key? key, required this.onDirectionChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      child: Joystick(
        mode: JoystickMode.all,
        period: Duration(milliseconds: 50),
        listener: (details) {
          onDirectionChanged(
              Offset(details.x, details.y)); // or details.position
        },
      ),
    );
  }
}

class PlayerData {
  final Offset position;
  final bool isChaser;

  PlayerData({required this.position, required this.isChaser});
}

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fieldPaint = Paint()
      ..color = Colors.green[800]!
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw field background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    // Draw center circle
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.height / 5, linePaint);

    // Draw center line
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), linePaint);

    // Draw penalty areas
    final penaltyAreaWidth = size.width / 5;
    final penaltyAreaHeight = size.height / 3;
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - penaltyAreaHeight) / 2,
            penaltyAreaWidth, penaltyAreaHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width - penaltyAreaWidth,
            (size.height - penaltyAreaHeight) / 2,
            penaltyAreaWidth,
            penaltyAreaHeight),
        linePaint);

    // Draw goal areas
    final goalAreaWidth = size.width / 10;
    final goalAreaHeight = size.height / 5;
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - goalAreaHeight) / 2, goalAreaWidth,
            goalAreaHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - goalAreaWidth,
            (size.height - goalAreaHeight) / 2, goalAreaWidth, goalAreaHeight),
        linePaint);

    // Draw corner arcs
    final cornerRadius = size.width / 20;
    canvas.drawArc(Rect.fromLTWH(0, 0, cornerRadius * 2, cornerRadius * 2), 0,
        3.14 / 2, false, linePaint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - cornerRadius * 2, 0, cornerRadius * 2,
            cornerRadius * 2),
        3.14 / 2,
        3.14 / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromLTWH(0, size.height - cornerRadius * 2, cornerRadius * 2,
            cornerRadius * 2),
        3.14 * 3 / 2,
        3.14 / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - cornerRadius * 2,
            size.height - cornerRadius * 2, cornerRadius * 2, cornerRadius * 2),
        3.14,
        3.14 / 2,
        false,
        linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class GamePainter extends CustomPainter {
  final PlayerData currentPlayer;
  final Map<String, PlayerData> players;

  GamePainter(this.currentPlayer, this.players);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint chaserPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final Paint runnerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw current player
    canvas.drawCircle(currentPlayer.position, 10,
        currentPlayer.isChaser ? chaserPaint : runnerPaint);

    // Draw other players
    players.forEach((id, player) {
      if (player.position != currentPlayer.position) {
        canvas.drawCircle(
            player.position, 10, player.isChaser ? chaserPaint : runnerPaint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return currentPlayer != oldDelegate.currentPlayer ||
        players != oldDelegate.players;
  }
}
