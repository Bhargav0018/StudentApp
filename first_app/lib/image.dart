import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Image Widget")),
        body: Center(
          child: Image.network(
            "https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg",
            width: 200,
          ),
        ),
      ),
    ),
  );
}