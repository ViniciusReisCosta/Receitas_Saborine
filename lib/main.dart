import 'package:flutter/material.dart';
import 'screens/HomeScreen.dart';

void main() {
  runApp(RecipeApp());
}

class RecipeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Tela inicial com Splash
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Navega diretamente para a HomeScreen após construir a tela Splash
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.orange, // Cor de fundo laranja imediatamente
      body: Center(
        child: Image.asset(
          'assets/logo.png', // Caminho da sua logo
          width: 200, // Ajuste o tamanho conforme necessário
          height: 200, // Ajuste o tamanho conforme necessário
        ),
      ),
    );
  }
}
