import 'package:flutter/material.dart';
import 'package:noticias/views/AdminPage.dart';
import 'package:noticias/views/HomePage.dart';

import 'package:noticias/views/exceptions/Page404.dart';
import 'package:noticias/views/mapa.dart';
import 'package:noticias/views/registerView.dart';
import 'package:noticias/views/sessionview.dart';
import 'package:noticias/views/userEditProfile.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SessionView(),
      initialRoute: "/",
      routes: {
        "/home": (context) => const SessionView(),
        "/register": (context) => const RegisterView(),
        "/principal": (context) => const HomePage(),
        "/editarPerfilUser": (context) =>  UserEditProfile(),
        "/admin": (context) => const AdminPage(),
        "/mapa": (context) => const Mapa(),
      },
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Page404(),
      ),
    );
  }
}
