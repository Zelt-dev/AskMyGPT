import 'package:flutter/material.dart';

class ThinkingAnimation extends StatefulWidget {
  const ThinkingAnimation({super.key});
  @override
  _ThinkingAnimationState createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    double delay = index * 0.3;
    return FadeTransition(
      opacity: DelayTween(delay: delay).animate(_controller),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildDot(0), _buildDot(1), _buildDot(2)],
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  final double delay;
  DelayTween({this.delay = 0.0}) : super(begin: 0.0, end: 1.0);

  @override
  double lerp(double t) {
    double adjusted = (t + delay) % 1.0;
    if (adjusted < 0.5) {
      return adjusted * 2;
    } else {
      return (1.0 - adjusted) * 2;
    }
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}