import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Row Widget")),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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