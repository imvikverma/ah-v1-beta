// Minimal test to verify Flutter can render
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xff050816),
        body: const Center(
          child: Text(
            'Flutter is working!',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    ),
  );
}

