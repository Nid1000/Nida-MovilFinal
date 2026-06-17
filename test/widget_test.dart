import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EECF),

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6E4),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.store, color: Colors.orange),
            SizedBox(width: 6),
            Text(
              'Delicias',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.mail_outline, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.calendar_today_outlined, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.star_border, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.menu, color: Colors.black),
          SizedBox(width: 10),
        ],
      ),

      // ===== BODY =====
      body: Column(
        children: [
          // ===== CATEGORÍAS =====
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Text('TODOS', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('PASTELES'),
                Text('PANES'),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // ===== TEXTO BIENVENIDA =====
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'BIENVENIDO A LA PANADERIA\n'
                      'Y PASTELERIA DELICIAS DEL\n'
                      'CENTRO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== LOGO =====
                  Container(
                    height: 80,
                    width: 200,
                    alignment: Alignment.center,
                    color: Colors.white,
                    child: const Text(
                      'Delicias',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== BOTONES =====
                  _loginButton('google'),
                  _loginButton('facebook'),
                  _loginButton('numero de telefono'),

                  const SizedBox(height: 30),

                  // ===== PROMOCIÓN =====
                  Container(
                    height: 120,
                    width: 200,
                    alignment: Alignment.center,
                    color: Colors.orange,
                    child: const Text(
                      'PROMOCIÓN',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ===== BOTTOM NAV =====
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'VISITAR TIENDA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ],
      ),
    );
  }

  // ===== BOTÓN REUTILIZABLE =====
  Widget _loginButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: 220,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE6B566),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
