import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('adoptar mascotas'),
      ),
      body: const Center(
        child: Text('aqui iRA el swipe'),   //funciona la conexion
      ),
    );
  }
}