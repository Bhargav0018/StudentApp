import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Card Widget")),
        body: Center(
          child: Card(
            elevation: 10,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Flutter Card"),
            ),
          ),
        ),
      ),
    ),
  );
}