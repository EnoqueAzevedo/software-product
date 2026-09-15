import 'package:flutter/material.dart';

// Tela principal que será aberta depois do login
class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
      ),

      // Conteúdo provisório da agenda
      body: const Center(
        child: Text(
          'Bem-vindo à sua agenda!',
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}