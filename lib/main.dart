import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: "PATITAS",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,     //aqui definimos el material design 3
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)  //CAMBIAR COLOR A FUTURO
      ),


      home: const Scaffold(
        body: Center(
          child: Text('jansito bellako'),    //CAMBIAR TEXTO, es solo prueba
        ),
      ),
    );
  }
}



//APLICACION VACIA jasn chupalo
