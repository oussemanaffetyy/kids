import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/default_model.dart';

class Fruits extends StatefulWidget {
  @override
  _FruitsState createState() => _FruitsState();
}

class _FruitsState extends State<Fruits> {
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final backgroundPath = isTablet
        ? 'assets/images/bgtablet.png'
        : 'assets/images/bgphone.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: buildModels(),
          ),
        ],
      ),
    );
  }

  Widget buildModels() {
    return ListView.builder(
      itemCount: fruitsList.length,
      itemBuilder: (context, index) {
        final Object? colorValue = fruitsList[index]['color'];
        final Color? color = colorValue is Color ? colorValue : null;
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: fruitsList[index]['name'].toString(),
              image: fruitsList[index]['imagePath'].toString(),
              color: color),
        );
      },
    );
  }
}
