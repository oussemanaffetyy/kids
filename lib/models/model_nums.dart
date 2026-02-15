import 'package:flutter/material.dart';
import 'package:project_v1/constants.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_widgets/animated_widgets.dart';
import 'package:project_v1/services/tts_helper.dart';

class CustomCardModel {
  String title, subImage, image;
  final Color? color;
  CustomCardModel({
    required this.title,
    required this.subImage,
    required this.image,
    this.color,
  });
}

class ModelStyle extends StatefulWidget {
  final CustomCardModel cardModel;
  ModelStyle({required this.cardModel});

  @override
  State<ModelStyle> createState() => _ModelStyleState();
}

class _ModelStyleState extends State<ModelStyle> {
  final FlutterTts flutterTts = FlutterTts();
  bool flag = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await TtsHelper.configureArabic(
        flutterTts,
        pitch: 1.0,
        volume: 1.0,
        speechRate: 0.45,
      );
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = true;
    const bgTop = 30.0;
    const bgHeight = 180.0;
    const imageWidth = 135.0;
    const imageHeight = 160.0;
    final bgWidth = ScreenSize(context).width * 0.9;
    final bgColor = widget.cardModel.color ?? AppColors.crimson;
    return Container(
      height: 230,
      child: Column(
        children: [
          Container(
            margin: isRtl
                ? EdgeInsets.only(left: 10, right: 20)
                : EdgeInsets.only(left: 20, right: 10),
            height: 230,
            child: Stack(
              children: [
                Positioned(
                  top: 30,
                  child: Container(
                    height: 180,
                    width: bgWidth,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  top: bgTop,
                  child: SizedBox(
                    height: bgHeight,
                    width: bgWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ShakeAnimatedWidget(
                            enabled: flag,
                            duration: Duration(milliseconds: 150),
                            shakeAngle: Rotation.deg(z: 10),
                            curve: Curves.linear,
                            child: Card(
                              color: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  //Music().volDown();
                                  await TtsHelper.speak(
                                      flutterTts, widget.cardModel.title);
                                  setState(() => flag = true);

                                  Future.delayed(Duration(milliseconds: 650),
                                      () {
                                    setState(() => flag = false);
                                  });

                                  // Future.delayed(Duration(milliseconds: 900), () {
                                  //   Music().volUp();
                                  // });
                                },
                                child: Container(
                                  height: imageHeight,
                                  width: imageWidth,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              AppColors.white.withOpacity(0.3),
                                          spreadRadius: 2.5,
                                          blurRadius: 4,
                                          offset: Offset(0.5, 1.5))
                                    ],
                                    image: DecorationImage(
                                        image: AssetImage(
                                            this.widget.cardModel.image),
                                        fit: BoxFit.fill),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  PrimaryText(
                                    text: this.widget.cardModel.title,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                    size: 35,
                                  ),
                                  Container(
                                    height: 65,
                                    width: 65,
                                    child: Image(
                                        image: AssetImage(
                                            this.widget.cardModel.subImage),
                                        fit: BoxFit.contain),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
