import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/model_nums.dart';

class NumsScreen extends StatefulWidget {
  @override
  _NumsScreenState createState() => _NumsScreenState();
}

class _NumsScreenState extends State<NumsScreen> {
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
      itemCount: numsList.length,
      itemBuilder: (context, index) {
        final Object? colorValue = numsList[index]['color'];
        final Color? color = colorValue is Color ? colorValue : null;
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: numsList[index]['name'].toString(),
              subImage: numsList[index]['counterPath'].toString(),
              image: numsList[index]['imagePath'].toString(),
              color: color),
        );
      },
    );
  }
}
