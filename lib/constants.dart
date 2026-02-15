import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:audioplayers/audioplayers.dart';

//RESPONSIVE SCREENS
class ScreenSize {
  BuildContext context;

  ScreenSize(this.context) : assert(true);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
}

// //USED COLORS
// class AppColors {
//   static const white = Color(0xffEEEEEE);
//   static const black = Color(0xff1e212d);
//   static const backGround = Color(0xff87C7F1);
//   static const yellow = Color(0xff8FDDE7);
//   //  static const secondary = Color(0xff8eecf5);
//   static const crimson = Color(0xffEACFFF);
//   static const secondary = Color(0xffdaf2dc);
//   static const orange = Color(0xffffab4c);
//   static const Lpink = Color(0xffffcce7);
//   static const sage = Color(0xffdaf2dc);
//   static const tale = Color(0xffdaf2dc);
// }

//USED COLORS
class AppColors {
  static const white = Color(0xffEEEEEE);
  static const black = Color(0xff1e212d);
  static const backGround = Color(0xffaf8aff);
  static const secondary = Color(0xff5fffe0);
  static const crimson = Color(0xffff5f7e);
  static const yellow = Color(0xfffbe698);
  static const orange = Color(0xffff884b);
  static const Lpink = Color(0xffffcce7);
  static const sage = Color(0xffdaf2dc);
  static const pale = Color(0xffeacfff);
  static const tale = Color(0xffdaf2dc);
}

//FONT STYLING
class PrimaryText extends StatelessWidget {
  final double size;
  final FontWeight fontWeight;
  final Color color;
  final String text;
  final double height;

  const PrimaryText({
    required this.text,
    this.fontWeight: FontWeight.w400,
    this.color: AppColors.black,
    this.size: 20,
    this.height: 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.almarai(
        height: height,
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

//BACKGROUND MUSIC CONTROLLER
// class Music {
//   static AudioPlayer music = AudioPlayer();
//   static AudioCache player = AudioCache(fixedPlayer: music);
//   void play() {
//     player.loop("voices/music.mp3", volume: 0.85);
//   }
//   volDown() {
//     music.setVolume(0.25);
//   }
//   volUp() {
//     music.setVolume(0.85);
//   }
// }

//CATEGORIES
const CardsList = [
  {
    'imagePath': 'assets/images/ecole_cognitive.png',
    'name': 'المدرسة',
  },
  {
    'imagePath': 'assets/images/biblio_linguistique.png',
    'name': 'المكتبة',
  },
  {
    'imagePath': 'assets/images/parc_moteur.png',
    'name': 'الحديقة',
  },
  {
    'imagePath': 'assets/images/maison_sociale.png',
    'name': 'البيت',
  },
];

//ROUTES (Home categories)
const routesList = [
  {'routePath': '/CognitiveGames'},
  {'routePath': '/LinguisticGames'},
  {'routePath': '/MotorGames'},
  {'routePath': '/SocialGames'},
];

const GamesList = [
  {'GameName': 'وصلة', 'imagePath': 'assets/games/color.png'},
  {'GameName': 'ميمو', 'imagePath': 'assets/games/memo.png'},
  {'GameName': 'الأرقام', 'imagePath': 'assets/games/logonumbers.png'},
  {'GameName': 'الحروف', 'imagePath': 'assets/games/gameletters.png'},
  {'GameName': 'العائلة', 'imagePath': 'assets/games/familygame.png'},
  {'GameName': 'الفواكه والخضروات', 'imagePath': 'assets/games/FruitsVegetablesGame.png'},
  {'GameName': 'ركّب الصورة', 'imagePath': 'assets/games/puzzlesgame.png'},
];

const gamesRoutes = [
  {'routePath': '/Color'},
  {'routePath': '/Memory'},
  {'routePath': '/NumbersGame'},
  {'routePath': '/LettersQuizGame'},
  {'routePath': '/FamilyGame'},
  {'routePath': '/FruitsVegetablesGame'},
  {'routePath': '/PuzzlesGame'},
];

// Category game lists
const cognitiveGames = [
  {'title': 'الألوان', 'imagePath': 'assets/games/color.png', 'route': '/Color'},
  {'title': 'ميمو', 'imagePath': 'assets/games/memo.png', 'route': '/Memory'},
  {'title': 'الأرقام', 'imagePath': 'assets/games/logonumbers.png', 'route': '/NumbersGame'},
  {'title': 'الفواكه والخضروات', 'imagePath': 'assets/games/FruitsVegetablesGame.png', 'route': '/FruitsVegetablesGame'},
  {'title': 'أيهما أكبر؟', 'imagePath': 'assets/games/compare.png', 'route': '/CompareGame'},
];

const linguisticGames = [
  {'title': 'الحروف', 'imagePath': 'assets/games/gameletters.png', 'route': '/LettersQuizGame'},
  {'title': 'اسمع وسمّي', 'imagePath': 'assets/games/listen.png', 'route': '/ListenNameGame'},
  {'title': 'ركّب الكلمة', 'imagePath': 'assets/games/LettersQuizGame.png', 'route': '/WordBuildGame'},
];

const motorGames = [
  {'title': 'ركّب الصورة', 'imagePath': 'assets/games/puzzlesgame.png', 'route': '/PuzzlesGame'},
  {'title': 'اتبع الخط', 'imagePath': 'assets/games/tracing.png', 'route': '/TracingGame'},
  {'title': 'اضغط على الهدف', 'imagePath': 'assets/games/target_star.png', 'route': '/TapTargetGame'},
];

const socialGames = [
  {'title': 'العائلة', 'imagePath': 'assets/games/familygame.png', 'route': '/FamilyGame'},
  {'title': 'كيف أشعر؟', 'imagePath': 'assets/games/emotions.png', 'route': '/EmotionGame'},
];

//NUMS LIST
const numsList = [
  {
    'imagePath': 'assets/numbers/0.png',
    'counterPath': 'assets/counters/hands0.png',
    'name': 'صفر',
  },
  {
    'imagePath': 'assets/numbers/1.png',
    'counterPath': 'assets/counters/hands1.png',
    'name': 'واحد',
  },
  {
    'imagePath': 'assets/numbers/2.png',
    'counterPath': 'assets/counters/hands2.png',
    'name': 'اثنان',
  },
  {
    'imagePath': 'assets/numbers/3.png',
    'counterPath': 'assets/counters/hands3.png',
    'name': 'ثلاثة',
  },
  {
    'imagePath': 'assets/numbers/4.png',
    'counterPath': 'assets/counters/hands4.png',
    'name': 'أربعة',
  },
  {
    'imagePath': 'assets/numbers/5.png',
    'counterPath': 'assets/counters/hands5.png',
    'name': 'خمسة',
  },
  {
    'imagePath': 'assets/numbers/6.png',
    'counterPath': 'assets/counters/hands6.png',
    'name': 'ستة',
  },
  {
    'imagePath': 'assets/numbers/7.png',
    'counterPath': 'assets/counters/hands7.png',
    'name': 'سبعة',
  },
  {
    'imagePath': 'assets/numbers/8.png',
    'counterPath': 'assets/counters/hands8.png',
    'name': 'ثمانية',
  },
  {
    'imagePath': 'assets/numbers/9.png',
    'counterPath': 'assets/counters/hands9.png',
    'name': 'تسعة',
  },
];

//ANIMALS LIST
const animalsList = [
  {
    'imagePath': 'assets/animals/leo.png',
    'voice': 'voices/leo.mp3',
    'name': 'أسد',
  },
  {
    'imagePath': 'assets/animals/duck.png',
    'voice': 'voices/duck.mp3',
    'name': 'بطة',
  },
  {
    'imagePath': 'assets/animals/chicken.png',
    'voice': 'voices/chicken.mp3',
    'name': 'دجاجة',
  },
  {
    'imagePath': 'assets/animals/horse.png',
    'voice': 'voices/horse.mp3',
    'name': 'حصان',
  },
  {
    'imagePath': 'assets/animals/goat.png',
    'voice': 'voices/goat.mp3',
    'name': 'ماعز',
  },
  {
    'imagePath': 'assets/animals/cat.png',
    'voice': 'voices/cat.mp3',
    'name': 'قطة',
  },
  {
    'imagePath': 'assets/animals/mouse.png',
    'voice': 'voices/mouse.mp3',
    'name': 'فأر',
  },
  {
    'imagePath': 'assets/animals/frog.png',
    'voice': 'voices/frog.mp3',
    'name': 'ضفدع',
  },
  {
    'imagePath': 'assets/animals/dog.png',
    'voice': 'voices/dog.mp3',
    'name': 'كلب',
  },
  {
    'imagePath': 'assets/animals/cow.png',
    'voice': 'voices/cow.mp3',
    'name': 'بقرة',
  },
];

//LETTERS LIST
const lettersList = [
  {
    'imagePath': 'assets/letters/أ.png',
    'subImage': 'assets/letters/avatars/أرنب.png',
    'name': 'أ',
  },
  {
    'imagePath': 'assets/letters/ب.png',
    'subImage': 'assets/letters/avatars/بطة.png',
    'name': 'ب',
  },
  {
    'imagePath': 'assets/letters/ت.png',
    'subImage': 'assets/letters/avatars/تفاح.png',
    'name': 'ت',
  },
  {
    'imagePath': 'assets/letters/ث.png',
    'subImage': 'assets/letters/avatars/ثلج.png',
    'name': 'ث',
  },
  {
    'imagePath': 'assets/letters/ج.png',
    'subImage': 'assets/letters/avatars/جَزَر.png',
    'name': 'ج',
  },
  {
    'imagePath': 'assets/letters/ح.png',
    'subImage': 'assets/letters/avatars/حصان.png',
    'name': 'ح',
  },
  {
    'imagePath': 'assets/letters/خ.png',
    'subImage': 'assets/letters/avatars/خيمة.png',
    'name': 'خ',
  },
  {
    'imagePath': 'assets/letters/د.png',
    'subImage': 'assets/letters/avatars/دولفين.png',
    'name': 'د',
  },
  {
    'imagePath': 'assets/letters/ذ.png',
    'subImage': 'assets/letters/avatars/ذُره.png',
    'name': 'ذ',
  },
  {
    'imagePath': 'assets/letters/ر.png',
    'subImage': 'assets/letters/avatars/ريشة.png',
    'name': 'ر',
  },
  {
    'imagePath': 'assets/letters/ز.png',
    'subImage': 'assets/letters/avatars/زرافة.png',
    'name': 'ز',
  },
  {
    'imagePath': 'assets/letters/س.png',
    'subImage': 'assets/letters/avatars/سلحفاة.png',
    'name': 'س',
  },
  {
    'imagePath': 'assets/letters/ش.png',
    'subImage': 'assets/letters/avatars/شمعة.png',
    'name': 'ش',
  },
  {
    'imagePath': 'assets/letters/ص.png',
    'subImage': 'assets/letters/avatars/صقر.png',
    'name': 'ص',
  },
  {
    'imagePath': 'assets/letters/ض.png',
    'subImage': 'assets/letters/avatars/ضفدع.png',
    'name': 'ض',
  },
  {
    'imagePath': 'assets/letters/ط.png',
    'subImage': 'assets/letters/avatars/طائرة.png',
    'name': 'ط',
  },
  {
    'imagePath': 'assets/letters/ظ.png',
    'subImage': 'assets/letters/avatars/ظرف.png',
    'name': 'ظ',
  },
  {
    'imagePath': 'assets/letters/ع.png',
    'subImage': 'assets/letters/avatars/عصفور.png',
    'name': 'ع',
  },
  {
    'imagePath': 'assets/letters/غ.png',
    'subImage': 'assets/letters/avatars/غزالة.png',
    'name': 'غ',
  },
  {
    'imagePath': 'assets/letters/ف.png',
    'subImage': 'assets/letters/avatars/فراولة.png',
    'name': 'ف',
  },
  {
    'imagePath': 'assets/letters/ق.png',
    'subImage': 'assets/letters/avatars/قلم.png',
    'name': 'ق',
  },
  {
    'imagePath': 'assets/letters/ك.png',
    'subImage': 'assets/letters/avatars/كرة.png',
    'name': 'ك',
  },
  {
    'imagePath': 'assets/letters/ل.png',
    'subImage': 'assets/letters/avatars/لمبة.png',
    'name': 'ل',
  },
  {
    'imagePath': 'assets/letters/م.png',
    'subImage': 'assets/letters/avatars/موز.png',
    'name': 'م',
  },
  {
    'imagePath': 'assets/letters/ن.png',
    'subImage': 'assets/letters/avatars/نجمة.png',
    'name': 'ن',
  },
  {
    'imagePath': 'assets/letters/ه.png',
    'subImage': 'assets/letters/avatars/هرم.png',
    'name': 'ه',
  },
  {
    'imagePath': 'assets/letters/و.png',
    'subImage': 'assets/letters/avatars/وردة.png',
    'name': 'و',
  },
  {
    'imagePath': 'assets/letters/ي.png',
    'subImage': 'assets/letters/avatars/يد.png',
    'name': 'ي',
  },
];

//FAMILY LIST
const familyList = [
  {
    'imagePath': 'assets/family/0.png',
    'name': 'الجد',
  },
  {
    'imagePath': 'assets/family/1.png',
    'name': 'الجدة',
  },
  {
    'imagePath': 'assets/family/2.png',
    'name': 'الأب',
  },
  {
    'imagePath': 'assets/family/3.png',
    'name': 'الأم',
  },
  {
    'imagePath': 'assets/family/4.png',
    'name': 'العم/الخال',
  },
  {
    'imagePath': 'assets/family/5.png',
    'name': 'العمة/الخالة',
  },
  {
    'imagePath': 'assets/family/6.png',
    'name': 'الابن',
  },
  {
    'imagePath': 'assets/family/7.png',
    'name': 'الابنة',
  },
  {
    'imagePath': 'assets/family/8.png',
    'name': 'ابن/ابنة العم',
  },
];

const fruitsList = [
  {
    'imagePath': 'assets/fruits/مانجو.png',
    'name': 'مانجو',
  },
  {
    'imagePath': 'assets/fruits/بطيخ.png',
    'name': 'بطيخ',
  },
  {
    'imagePath': 'assets/fruits/كيوي.png',
    'name': 'كيوي',
  },
  {
    'imagePath': 'assets/fruits/عنب.png',
    'name': 'عنب',
  },
  {
    'imagePath': 'assets/fruits/أناناس.png',
    'name': 'أناناس',
  },
];

const vegetablesList = [
  {
    'imagePath': 'assets/vegetables/بطاطس.png',
    'name': 'بطاطس',
  },
  {
    'imagePath': 'assets/vegetables/بازلاء.png',
    'name': 'بازلاء',
  },
  {
    'imagePath': 'assets/vegetables/فلفل.png',
    'name': 'فلفل',
  },
  {
    'imagePath': 'assets/vegetables/باذنجان.png',
    'name': 'باذنجان',
  },
  {
    'imagePath': 'assets/vegetables/خيار.png',
    'name': 'خيار',
  },
];
