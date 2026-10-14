
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Text Widget")),
        body: Center(
          child: Text(
            "Hello Flutter!",
            style: TextStyle(fontSize: 30, color: Colors.blue),
          ),
        ),
      ),
    ),
  );
}