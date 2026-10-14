import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Column Widget")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home),
            Icon(Icons.person),
            Icon(Icons.settings),
          ],
        ),
      ),
    ),
  );
}