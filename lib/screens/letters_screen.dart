import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/model_letters.dart';

class LettersScreen extends StatefulWidget {
  @override
  _LettersScreenState createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  @override
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
      itemCount: lettersList.length,
      itemBuilder: (context, index) {
        final Object? colorValue = lettersList[index]['color'];
        final Color? color = colorValue is Color ? colorValue : null;
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: lettersList[index]['name'].toString(),
              subImage: lettersList[index]['subImage'].toString(),
              image: lettersList[index]['imagePath'].toString(),
              color: color),
        );
      },
    );
  }
}
