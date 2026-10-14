import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Icon Widget")),
        body: Center(child: Icon(Icons.favorite, color: Colors.blue, size: 80)),
      ),
    ),
  );
}