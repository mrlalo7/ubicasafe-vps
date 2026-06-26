import 'package:flutter/material.dart';
import 'package:ubicasafe/pages/informacion.dart';

class Portada extends StatefulWidget {
  const Portada({super.key});

  @override
  State<Portada> createState() => _PortadaState();
}

class _PortadaState extends State<Portada> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const Informacion()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/portada4.png'),
            fit: BoxFit.fill,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
