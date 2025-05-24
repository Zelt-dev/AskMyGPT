import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = true;

  void toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkBgColor = Colors.grey[900]!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          _isDarkTheme
              ? SystemUiOverlayStyle(
                systemNavigationBarColor: darkBgColor,
                systemNavigationBarIconBrightness: Brightness.light,
              )
              : SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      child: MaterialApp(
        title: 'AskMyGPT',
        debugShowCheckedModeBanner: false,
        theme:
            _isDarkTheme
                ? ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: Colors.grey[900],
                )
                : ThemeData.light().copyWith(
                  scaffoldBackgroundColor: Colors.white,
                ),
        home: ChatScreen(toggleTheme: toggleTheme, chatIndex: 0),
      ),
    );
  }
}