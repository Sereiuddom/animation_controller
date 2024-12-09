import 'package:flutter/material.dart';
import '../widgets/animated_balloon.dart';
import '../widgets/animated_balloon2.dart';


class HomePage extends StatelessWidget {

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text('Animations')),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                AnimatedBalloonWidget(),
                AnimatedBalloonWidget2(),
              ],
            ),
          ),
        ),
      ),
    );

  }

}