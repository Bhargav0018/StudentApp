import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Container Widget")),
        body: Center(
          child: Container(
            width: 200,
            height: 100,
            color: Colors.orange,
            child: Center(child: Text("Container")),
          ),
        ),
      ),
    ),
  );
}