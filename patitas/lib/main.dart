import 'package:flutter/material.dart';
import 'screens/feed_screen.dart';  //aqui importo para mostrar las pantallas de swipe

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      //definimos material design 3
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green, //COLOR TEMPORAL
      ),


      //home: const Scaffold(
      //  body: Center(
      //    child: Text('FUNCIONA MATERIAL DESIGN '),   //texto generico cabros CAMBIAR
      //  ),
      //),

      home: const FeedScreen(), //LA CONEXION


    );
  }
}
