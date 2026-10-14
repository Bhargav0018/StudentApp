import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("ListView")),
        body: ListView(
          children: [
            ListTile(title: Text("Apple")),
            ListTile(title: Text("Banana")),
            ListTile(title: Text("Orange")),
          ],
        ),
      ),
    ),
  );
}