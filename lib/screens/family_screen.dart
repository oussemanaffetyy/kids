import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/default_model.dart';

class FamilyScreen extends StatefulWidget {
  @override
  _FamilyScreenState createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
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
      itemCount: familyList.length,
      itemBuilder: (context, index) {
        final Object? colorValue = familyList[index]['color'];
        final Color? color = colorValue is Color ? colorValue : null;
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: familyList[index]['name'].toString(),
              image: familyList[index]['imagePath'].toString(),
              color: color),
        );
      },
    );
  }
}
