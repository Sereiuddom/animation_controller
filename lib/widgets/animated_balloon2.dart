import 'package:flutter/material.dart';

class AnimatedBalloonWidget2 extends StatefulWidget {
  @override
  _AnimatedBalloonWidgetState createState() => _AnimatedBalloonWidgetState();
}

class _AnimatedBalloonWidgetState extends State<AnimatedBalloonWidget2> with TickerProviderStateMixin {
  late AnimationController _controllerFloatUp;
  late AnimationController _controllerGrowSize;
  late AnimationController _controllerRotation;
  late AnimationController _controllerPulse;
  late AnimationController _controllerMoveSideways;
  late AnimationController _controllerPop;
  late AnimationController _controllerFloatAway; // Controller for floating away
  late List<AnimationController> _cloudControllers;
  late Animation<double> _animationFloatUp;
  late Animation<double> _animationGrowSize;
  late Animation<double> _animationRotation;
  late Animation<double> _animationPulse;
  late Animation<double> _animationMoveSideways;
  late Animation<double> _animationPopScale;
  late Animation<double> _animationPopOpacity;
  late Animation<double> _animationFloatAway; // Animation for floating away
  late List<Animation<double>> _cloudAnimations;

  Offset _balloonPosition = Offset(0, 0);
  bool _hasPopped = false;
  bool _hasReachedTop = false; // Flag to check if the balloon reached the top

  @override
  void initState() {
    super.initState();

    _controllerFloatUp = AnimationController(duration: Duration(seconds: 10), vsync: this); // Float up
    _controllerGrowSize = AnimationController(duration: Duration(seconds: 4), vsync: this); // Grow size
    _controllerRotation = AnimationController(duration: Duration(seconds: 4), vsync: this); // Drifting rotation
    _controllerPulse = AnimationController(duration: Duration(seconds: 3), vsync: this); // Pulse
    _controllerMoveSideways = AnimationController(duration: Duration(seconds: 5), vsync: this); // Sideways
    _controllerPop = AnimationController(duration: Duration(milliseconds: 200), vsync: this); // Pop
    _controllerFloatAway = AnimationController(duration: Duration(seconds: 3), vsync: this); // Float away

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

    _animationPulse = Tween(begin: 1.0, end: 1.08).animate(
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

    // New animation to make the balloon float away once it reaches the top
    _animationFloatAway = Tween(begin: 0.0, end: -200.0).animate(
      CurvedAnimation(parent: _controllerFloatAway, curve: Curves.easeIn),
    );

    // Start animations
    _controllerRotation.forward();
    _controllerPulse.forward();
    _controllerFloatUp.forward();
    _controllerGrowSize.forward();
    _controllerMoveSideways.forward();

    // Listen for the float-up animation's completion and start the float away
    _controllerFloatUp.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasPopped) {
        setState(() {
          _hasReachedTop = true;
        });
        _controllerFloatAway.forward(); // Trigger float away animation
      }
    });

    // Trigger balloon pop only if it hasn't reached the top to float away
    Future.delayed(Duration(seconds: 10), () {
      if (!_hasReachedTop) { // Only pop if not floating away
        setState(() {
          _hasPopped = true;
        });
        _controllerPop.forward();
      }
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
    _controllerFloatAway.dispose();
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
          _animationFloatAway, // Include the new float away animation
          ..._cloudAnimations,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _balloonPosition.dx + _animationMoveSideways.value,
              _hasReachedTop
                  ? _animationFloatAway.value // Apply float away once at the top
                  : _animationFloatUp.value + _balloonPosition.dy,
            ),
            child: Transform.rotate(
              angle: _animationRotation.value, // Drift effect added here
              child: Transform.scale(
                scale: _hasPopped ? _animationPopScale.value : _animationPulse.value,
                child: Opacity(
                  opacity: _hasPopped ? _animationPopOpacity.value : 1.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cloud background animations
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

                      // Balloon with surrounding shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25), // Darker shadow for visibility
                              blurRadius: 15.0,                      // Increased blur for soft effect
                              spreadRadius: 1.0,                     // Spreads the shadow around the balloon
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [Colors.blueAccent, Colors.purpleAccent],
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
