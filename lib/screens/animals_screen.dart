import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:project_v1/models/model_animals.dart';

class AnimalScreen extends StatefulWidget {
  @override
  _AnimalScreenState createState() => _AnimalScreenState();
}

class _AnimalScreenState extends State<AnimalScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final backgroundPath = isTablet
        ? 'assets/images/2048x2732.png'
        : 'assets/images/1080x2400.png';

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
      itemCount: animalsList.length,
      itemBuilder: (context, index) {
        return ModelStyle(
          cardModel: new CustomCardModel(
              title: animalsList[index]['name'].toString(),
              voice: animalsList[index]['voice'].toString(),
              image: animalsList[index]['imagePath'].toString()),
        );
      },
    );
  }
}
