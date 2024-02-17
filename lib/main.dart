import 'package:flutter/material.dart';
import 'package:inflearn_cf_live_chat/screen/home_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansKR'
      ),
      home: HomeScreen(),
    ),
  );
}

