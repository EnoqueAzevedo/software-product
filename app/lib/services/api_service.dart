import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL pública do backend
  static const String baseUrl = 'https://agenda-pulcro-api.onrender.com';

  // Decodifica corretamente as respostas da API como UTF-8.
  static String _decodificarResposta(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  // Testa a conexão com a API
  static Future<String> testarConexao() async {
    final response = await http.get(Uri.parse('$baseUrl/'));

    if (response.statusCode != 200) {
      throw Exception('API indisponível');
    }

    return _decodificarResposta(response);
  }

  // Cria um cadastro provisório
  static Future<String> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmacaoSenha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'confirmacao_senha': confirmacaoSenha,
      }),
    );

    final resposta = _decodificarResposta(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final data = jsonDecode(resposta);

        throw Exception(
          data['detail'] ?? 'Não foi possível realizar o cadastro',
        );
      } on FormatException {
        throw Exception('Não foi possível realizar o cadastro');
      }
    }

    final data = jsonDecode(resposta);

    return data['mensagem'];
  }

  // Faz login e salva o token de autenticação
  static Future<String> login({
    required String email,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': senha},
    );

    if (response.statusCode != 200) {
      throw Exception('Email ou senha inválidos');
    }

    final data = jsonDecode(_decodificarResposta(response));
    final token = data['access_token'] as String;

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
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar o usuário');
    }

    return _decodificarResposta(response);
  }

  // Busca os serviços cadastrados
  static Future<List<dynamic>> getServicos() async {
    final response = await http.get(Uri.parse('$baseUrl/servicos/'));

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar os serviços');
    }

    return jsonDecode(_decodificarResposta(response)) as List<dynamic>;
  }

  // Busca os profissionais que realizam o serviço selecionado
  static Future<List<dynamic>> getProfissionais({
    required int servicoId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profissionais/servico/$servicoId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar os profissionais');
    }

    return jsonDecode(_decodificarResposta(response)) as List<dynamic>;
  }

  // Busca os horários disponíveis para serviço,
  // profissional e data selecionados
  static Future<List<dynamic>> getHorarios({
    required int servicoId,
    required int profissionalId,
    required String data,
  }) async {
    final uri = Uri.parse('$baseUrl/agendamentos/horarios').replace(
      queryParameters: {
        'servico_id': servicoId.toString(),
        'profissional_id': profissionalId.toString(),
        'data': data,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Não foi possível buscar os horários disponíveis');
    }

    return jsonDecode(_decodificarResposta(response)) as List<dynamic>;
  }

  // Cria um agendamento
  static Future<void> criarAgendamento({
    required int servicoId,
    required int profissionalId,
    required String data,
    required String horario,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não está autenticado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/agendamentos/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'servico_id': servicoId,
        'profissional_id': profissionalId,
        'data_agendamento': data,
        'horario_inicio': horario,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String mensagem = 'Não foi possível confirmar o agendamento';

      try {
        final resposta = _decodificarResposta(response);
        final data = jsonDecode(resposta);

        if (data is Map && data['detail'] != null) {
          mensagem = data['detail'].toString();
        }
      } catch (_) {
        // Mantém a mensagem padrão se a resposta não for JSON.
      }

      throw Exception(mensagem);
    }
  }
}
