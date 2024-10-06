import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static double percentage = 100.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RadialProgressWidget(percentage),
    );
  }
}

class Particle {
  double orbit;
  late double originalOrbit;
  late double theta;
  late double opacity;
  late Color color;

  Particle(this.orbit) {
    originalOrbit = orbit;
    // 파티클이 위치할 극좌표를 랜덤하게 생성한다.
    theta = getRandomRange(0.0, 360.0) * pi * 180;
    opacity = getRandomRange(0.3, 1.0);
    color = Colors.white;
  }

  final rnd = Random();

  double getRandomRange(double min, double max) {
    return rnd.nextDouble() * (max - min) + min;
  }

  // 파티클이 위치할 극좌표를 바깥으로 이동시킨다.
  void update() {
    orbit += 0.1;
    opacity -= 0.0025;
    // 투명도가 0보다 작다면 파티클을 원래 위치한 극좌표로 이동시킨다.
    if (opacity <= 0.0) {
      orbit = originalOrbit;
      // 파티클의 위치는 이미 고정되어있지만 투명도가 0 이하가 되면
      // 랜덤하게 투명도를 설정함으로써 여러개의 파티클이 계속 생기는 듯한 착시를 일으킨다.
      opacity = getRandomRange(0.1, 1.0);
    }
  }
}

class RadialProgressWidget extends StatefulWidget {
  final double percentage;

  const RadialProgressWidget(this.percentage, {super.key});

  @override
  State<RadialProgressWidget> createState() => _RadialProgressWidgetState();
}

class _RadialProgressWidgetState extends State<RadialProgressWidget> {
  var value = 0.0;
  final speed = 0.5;
  late Timer timer;
  final List<Particle> particles = List<Particle>.generate(200, (index) => Particle(radialSize + thickness / 2.0));

  @override
  void initState() {
    super.initState();
    // 초당 60회(60fps) 실행되는 타이머를 실행한다.
    timer = Timer.periodic(
      // 나눗셈의 몫 결과값에서 소수점을 버리고 정수만을 반환한다.
      const Duration(milliseconds: 1000 ~/ 60),
      (timer) {
        var v = value;
        if (v <= widget.percentage) {
          v += speed;
        } else {
          // 퍼센테이지가 100에 도달하면 파티클 업데이트를 수행한다.
          setState(() {
            for (var p in particles) {
              p.update();
            }
          });
        }

        setState(() {
          value = v;
        });
      },
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이 프로젝트에서는 setState() 메서드를 통해 CustomPainter를 다시 그린다.
    return CustomPaint(
      painter: RadialProgressPainter(value, particles),
    );
  }
}

// 극좌표를 직교좌표로 변환한다.
Offset polarToCartesian(double r, double theta) {
  final dx = r * cos(theta);
  final dy = r * sin(theta);
  return Offset(dx, dy);
}

const double radialSize = 100.0;
const double thickness = 10.0;
const TextStyle textStyle = TextStyle(color: Colors.red, fontSize: 50.0, fontWeight: FontWeight.bold);

const Color col1 = Color(0xff110f14);
const Color col2 = Color(0xff2a2732);
const Color col3 = Color(0xff3c393f);
const Color col4 = Color(0xff6047f5);
const Color col5 = Color(0xffa3b0ef);

class RadialProgressPainter extends CustomPainter {
  final double percentage;
  final List<Particle> particles;

  RadialProgressPainter(this.percentage, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = Colors.grey);

    final c = Offset(size.width / 2.0, size.height / 2.0);
    drawBackground(canvas, c, size.height / 2.0);
    final rect = Rect.fromCenter(center: c, width: 2 * radialSize, height: 2 * radialSize);

    // canvas.drawRect(rect, Paint()..color = Colors.black26);
    drawGuid(canvas, c, radialSize);
    drawArc(canvas, rect);
    drawTextCentered(canvas, c, '${percentage.toInt()}', textStyle, radialSize * 2);
    if (percentage >= 100) {
      drawParticles(canvas, c);
    }
  }

  void drawBackground(Canvas canvas, Offset c, double extent) {
    final rect = Rect.fromCenter(center: c, width: extent, height: extent);
    final bgPaint = Paint()
      ..shader = const RadialGradient(colors: [col1, col2]).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPaint(bgPaint);
  }

  void drawParticles(Canvas canvas, Offset c) {
    for (var p in particles) {
      final cc = polarToCartesian(p.orbit, p.theta) + c;
      final paint = Paint()..color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(cc, 1.0, paint);
    }
  }

  void drawGuid(Canvas canvas, Offset c, double radius) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade400;
    canvas.drawCircle(c, radius, paint);
  }

  void drawArc(Canvas canvas, Rect rect) {
    final fgPaint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [col4, col5],
        tileMode: TileMode.mirror,
      ).createShader(rect);
    const startAngle = -90.0 * pi / 180.0;
    final sweepAngle = 360 * percentage / 100.0 * pi / 180.0;

    canvas.drawArc(rect, startAngle, sweepAngle, false, fgPaint);
  }

  Size drawTextCentered(Canvas canvas, Offset position, String text, TextStyle style, double maxWidth) {
    final tp = measureText(text, style, maxWidth, TextAlign.center);
    // 텍스트는 센터를 중심으로 크기를 가진다.
    // 텍스트를 정중앙에 위치시키려면 텍스트의 높이와 너비를 반으로 나눠 x,y 포인트를 이동한다.
    tp.paint(canvas, position + Offset(-tp.width / 2.0, -tp.height / 2.0));
    return tp.size;
  }

  TextPainter measureText(String text, TextStyle style, double maxWidth, TextAlign alignment) {
    final span = TextSpan(text: text, style: style);
    final tp = TextPainter(text: span, textAlign: alignment, textDirection: TextDirection.ltr);
    tp.layout(minWidth: 0, maxWidth: maxWidth);
    return tp;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
