import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'pages/home_screen.dart';


void main() {
  testarApi();
  testarServicos();

  runApp(const AgendaPulcroApp());
}


// Testa a comunicação com o backend
Future<void> testarApi() async {
  try {
    final resposta = await ApiService.testarConexao();

    print('RESPOSTA DA API: $resposta');
  } catch (e) {
    print('ERRO AO CONECTAR COM A API: $e');
  }
}


// Testa a busca dos serviços
Future<void> testarServicos() async {
  try {
    final servicos = await ApiService.getServicos();

    print('SERVIÇOS DA API: $servicos');
  } catch (e) {
    print('ERRO AO BUSCAR SERVIÇOS: $e');
  }
}


// Aplicativo principal
class AgendaPulcroApp extends StatelessWidget {
  const AgendaPulcroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Pulcro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      // home: const HomeScreen(),
    );
  }
}