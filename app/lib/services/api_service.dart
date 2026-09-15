import 'dart:convert'; // Converte respostas JSON

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Guarda o token


// Serviço responsável pelas chamadas para a API
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';


  // Testa a conexão com o backend
  static Future<String> testarConexao() async {
    final response = await http.get(
      Uri.parse('$baseUrl/'),
    );

    return response.body;
  }


  // Envia um novo cadastro para o backend
  static Future<String> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmacaoSenha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'confirmacao_senha': confirmacaoSenha,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['detail'] ?? 'Não foi possível realizar o cadastro',
      );
    }

    final data = jsonDecode(response.body);

    return data['mensagem'];
  }


  // Faz login e salva o token
  static Future<String> login({
    required String email,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': senha,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Email ou senha inválidos');
    }

    final data = jsonDecode(response.body);
    final token = data['access_token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    return token;
  }


  // Recupera o token salvo
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('access_token');
  }


  // Busca os dados do usuário autenticado
  static Future<String> getMe() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não está autenticado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar o usuário');
    }

    return response.body;
  }


  // Busca os serviços cadastrados no banco
  static Future<List<dynamic>> getServicos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/servicos/'),
    );

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar os serviços');
    }

    return jsonDecode(response.body);
  }
}