import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart'; // 우리가 만든 홈 화면 임포트

void main() async {
  // 1. 환경 변수(.env) 로드
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Shuffle',
      debugShowCheckedModeBanner: false, // 오른쪽 상단 디버그 띠 제거
      
      // 2. 앱의 전체적인 테마 설정 (스포티파이 느낌의 그린 & 다크)
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212), // 다크 모드 배경색
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF191414),
          elevation: 0,
        ),
      ),
      
      // 3. 앱이 시작될 때 처음 보여줄 화면
      home: const HomeScreen(), 
    );
  }
}