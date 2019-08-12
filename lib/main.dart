//import 'dart:convert';
//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sandtrack/root_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: new ThemeData(
        primaryColor: const Color(0xff004d40),
        primaryColorDark: const Color(0xff003e33),
        accentColor: const Color(0xff005B9A),
      ),
      home: RootPage(),
      debugShowCheckedModeBanner: false,
      //theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
