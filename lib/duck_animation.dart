import 'package:flutter/material.dart';

import 'package:toepen_cardgame/helpers/audio.dart';
import 'package:toepen_cardgame/helpers/custom_audio_player.dart';

class DuckAnimation extends StatefulWidget {
  @override
  _DuckAnimationState createState() => _DuckAnimationState();
}

class _DuckAnimationState extends State<DuckAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isWalkingRight = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {
          _isWalkingRight = !_isWalkingRight;
          if (_isWalkingRight) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        });
      }
    });

    _animation = Tween<double>(
      begin: -200,
      end: 600,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white,
            Colors.lightBlue,
            Colors.blue,
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                left: _animation.value,
                bottom: 10,
                child: GestureDetector(
                  onTap: () {
                    CustomAudioPlayer.playAudio(AudioPath(Audio.quack).path);
                  },
                  child: Transform.scale(
                      scaleX: _isWalkingRight ? 1 : -1,
                      child: const Image(
                        image: AssetImage('assets/duck.png'),
                        height: 40,
                      )
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
