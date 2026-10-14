import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: SwitchDemo()));

class SwitchDemo extends StatefulWidget {
  @override
  State<SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<SwitchDemo> {
  bool status = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Switch")),
      body: Center(
        child: Switch(
          value: status,
          onChanged: (v) {
            setState(() {
              status = v;
            });
          },
        ),
      ),
    );
  }
}