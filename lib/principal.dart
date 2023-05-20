import 'package:flutter/material.dart';

import 'intasistencia.dart';
import 'intreportes.dart';

class Principal extends StatefulWidget {
  const Principal({Key? key}) : super(key: key);

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {

  int _i = 0;

  void _cambiarIndice(int i){
    setState(() {
      _i = i;
    });
  }

  final List<Widget> _pag =[
    IntAsistencia(),
    IntReportes(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pag[_i],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_sharp), label: "Asistencias",),
          BottomNavigationBarItem(icon: Icon(Icons.event_repeat_outlined), label: "Reportes",),
        ],
        currentIndex: _i,
        showUnselectedLabels: false,
        backgroundColor: Colors.orange,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.deepOrangeAccent,
        onTap: _cambiarIndice,
        iconSize: 30,
      ),
    );
  }
}

