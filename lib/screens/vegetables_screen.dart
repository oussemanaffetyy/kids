import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/default_model.dart';

class Vegetables extends StatefulWidget {
  @override
  _VegetablesState createState() => _VegetablesState();
}

class _VegetablesState extends State<Vegetables> {
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
      itemCount: vegetablesList.length,
      itemBuilder: (context, index) {
        final Object? colorValue = vegetablesList[index]['color'];
        final Color? color = colorValue is Color ? colorValue : null;
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: vegetablesList[index]['name'].toString(),
              image: vegetablesList[index]['imagePath'].toString(),
              color: color),
        );
      },
    );
  }
}
