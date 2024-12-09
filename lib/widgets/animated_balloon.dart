import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AnimatedBalloonWidget extends StatefulWidget {
  @override
  _AnimatedBalloonWidgetState createState() => _AnimatedBalloonWidgetState();
}

class _AnimatedBalloonWidgetState extends State<AnimatedBalloonWidget> with TickerProviderStateMixin {
  late AnimationController _controllerFloatUp;
  late AnimationController _controllerGrowSize;
  late AnimationController _controllerRotation;
  late AnimationController _controllerPulse;
  late AnimationController _controllerMoveSideways;
  late AnimationController _controllerPop;
  late List<AnimationController> _cloudControllers;
  late Animation<double> _animationFloatUp;
  late Animation<double> _animationGrowSize;
  late Animation<double> _animationRotation;
  late Animation<double> _animationPulse;
  late Animation<double> _animationMoveSideways;
  late Animation<double> _animationPopScale;
  late Animation<double> _animationPopOpacity;
  late List<Animation<double>> _cloudAnimations;

  Offset _balloonPosition = Offset(0, 0);
  bool _hasPopped = false;

  final AudioPlayer _inflatePlayer = AudioPlayer();
  final AudioPlayer _windPlayer = AudioPlayer();
  final AudioPlayer _popPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _controllerFloatUp = AnimationController(duration: Duration(seconds: 10), vsync: this); // Float up
    _controllerGrowSize = AnimationController(duration: Duration(seconds: 4), vsync: this); // Grow size
    _controllerRotation = AnimationController(duration: Duration(seconds: 4), vsync: this); // Drifting rotation
    _controllerPulse = AnimationController(duration: Duration(seconds: 3), vsync: this); // Pulse
    _controllerMoveSideways = AnimationController(duration: Duration(seconds: 5), vsync: this); // Sideways
    _controllerPop = AnimationController(duration: Duration(milliseconds: 200), vsync: this); // Pop

    // Cloud controllers for background clouds
    _cloudControllers = List.generate(5, (index) {
      return AnimationController(duration: Duration(seconds: 10 + index * 2), vsync: this)..repeat(reverse: true);
    });

    // Cloud animations
    _cloudAnimations = _cloudControllers.map((controller) {
      return Tween(begin: -200.0, end: 200.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.linear),
      );
    }).toList();

    // Balloon animations
    _animationRotation = Tween(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _controllerRotation, curve: Curves.easeInOutSine),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controllerRotation.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controllerRotation.forward();
      }
    });

    _animationPulse = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controllerPulse, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controllerPulse.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controllerPulse.forward();
      }
    });

    _animationMoveSideways = Tween(begin: -50.0, end: 50.0).animate(
      CurvedAnimation(parent: _controllerMoveSideways, curve: Curves.easeInOutSine),
    );

    _animationPopScale = Tween(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controllerPop, curve: Curves.easeOut),
    );

    _animationPopOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controllerPop, curve: Curves.easeOut),
    );

    // Start animations
    _controllerRotation.forward();
    _controllerPulse.forward();
    _controllerFloatUp.forward();
    _controllerGrowSize.forward();
    _controllerMoveSideways.forward();

    // Play inflation sound when the balloon starts growing
    _controllerGrowSize.addListener(() {
      if (_controllerGrowSize.status == AnimationStatus.forward && _controllerGrowSize.value < 0.1) {
        _inflatePlayer.setAsset('assets/sounds/inflate.mp3');
        _inflatePlayer.play();
      }
    });

    // Play wind sound in a loop while the balloon floats
    _windPlayer.setAsset('assets/sounds/inflate.mp3');
    _windPlayer.setLoopMode(LoopMode.one);
    _windPlayer.play();

    // Trigger balloon pop sound if it pops after reaching the top
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        _hasPopped = true;
      });
      _controllerPop.forward();
      _popPlayer.setAsset('assets/sounds/inflate.mp3');
      _popPlayer.play();
    });
  }

  @override
  void dispose() {
    _controllerFloatUp.dispose();
    _controllerGrowSize.dispose();
    _controllerRotation.dispose();
    _controllerPulse.dispose();
    _controllerMoveSideways.dispose();
    _controllerPop.dispose();
    _inflatePlayer.dispose();
    _windPlayer.dispose();
    _popPlayer.dispose();
    for (var controller in _cloudControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _balloonHeight = MediaQuery.of(context).size.height / 2;
    double _balloonWidth = MediaQuery.of(context).size.width / 3;
    double _balloonBottomLocation = MediaQuery.of(context).size.height - _balloonHeight;

    // Balloon animations
    _animationFloatUp = Tween(begin: _balloonBottomLocation, end: 0.0).animate(
      CurvedAnimation(parent: _controllerFloatUp, curve: Curves.easeOutQuad),
    );

    _animationGrowSize = Tween(begin: 50.0, end: _balloonWidth).animate(
      CurvedAnimation(parent: _controllerGrowSize, curve: Curves.easeOutBack),
    );

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _balloonPosition += details.delta;
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _animationFloatUp,
          _animationGrowSize,
          _animationRotation,
          _animationPulse,
          _animationMoveSideways,
          _animationPopScale,
          _animationPopOpacity,
          ..._cloudAnimations,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _balloonPosition.dx + _animationMoveSideways.value,
              _animationFloatUp.value + _balloonPosition.dy,
            ),
            child: Transform.rotate(
              angle: _animationRotation.value,
              child: Transform.scale(
                scale: _hasPopped ? _animationPopScale.value : _animationPulse.value,
                child: Opacity(
                  opacity: _hasPopped ? _animationPopOpacity.value : 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(5, (index) {
                        return Positioned(
                          top: 40 + (index * 10),
                          left: _cloudAnimations[index].value,
                          child: Image.asset(
                            'assets/images/cloud1.png',
                            width: 200,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        );
                      }),

                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 15.0,
                              spreadRadius: 1.0,
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [Colors.orangeAccent, Colors.redAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            width: _animationGrowSize.value,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: Image.asset(
          'assets/images/balloon.png',
          height: _balloonHeight,
          width: _balloonWidth,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
