import 'package:flutter/material.dart';

import 'login_page.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Tela de cadastro
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _botaoHabilitado = false;
  bool _carregando = false;

  // Valida o formato do e-mail
  bool _validarEmail(String email) {
    final regex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    return regex.hasMatch(email);
  }

  // Verifica se existem três números consecutivos
  bool _temTresNumerosConsecutivos(String senha) {
    for (int i = 0; i < senha.length - 2; i++) {
      final a = senha.codeUnitAt(i);
      final b = senha.codeUnitAt(i + 1);
      final c = senha.codeUnitAt(i + 2);

      if (b == a + 1 && c == b + 1) {
        return true;
      }

      if (b == a - 1 && c == b - 1) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();

    _nomeController.addListener(_validarCampos);
    _emailController.addListener(_validarCampos);
    _senhaController.addListener(_validarCampos);
    _confirmarSenhaController.addListener(_validarCampos);
  }

  // Verifica se todos os campos estão válidos
  void _validarCampos() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    final nomeValido = nome.length >= 3;

    final emailValido = _validarEmail(email);

    final senhaValida = senha.length >= 6 &&
        !_temTresNumerosConsecutivos(senha);

    final senhasIguais =
        confirmarSenha.isNotEmpty && senha == confirmarSenha;

    final formularioValido =
        nomeValido &&
        emailValido &&
        senhaValida &&
        senhasIguais;

    if (formularioValido != _botaoHabilitado) {
      setState(() {
        _botaoHabilitado = formularioValido;
      });
    }
  }

  // Envia o cadastro para o backend
  Future<void> _criarConta() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
        ),
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final mensagem = await ApiService.cadastrar(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        confirmacaoSenha: _confirmarSenhaController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String mensagem = 'Não foi possível criar a conta.';

      if (e.toString().contains('já está cadastrado')) {
        mensagem = 'Este e-mail já está cadastrado.';
      } else if (e.toString().contains('cadastro pendente')) {
        mensagem = 'Este e-mail já possui um cadastro pendente.';
      } else if (e.toString().contains('não coincidem')) {
        mensagem = 'As senhas não coincidem.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // Volta para a tela de login
  void _irParaEntrar() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // Estilo padrão dos campos
  InputDecoration _decoracaoCampo(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.pillBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Cria o rótulo dos campos
  Widget _rotuloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),

              // Cabeçalho
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: AppColors.textOnDark,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cadastro',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Organize seu dia com simplicidade',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Vamos começar!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Crie sua conta para seus compromissos',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Cartão com o formulário
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotuloCampo('Nome Completo'),

                    TextField(
                      controller: _nomeController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _decoracaoCampo(
                        'Digite seu nome completo',
                      ),
                    ),

                    const SizedBox(height: 20),

                    _rotuloCampo('E-mail'),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _decoracaoCampo(
                        'ex: maria@clinica.com',
                      ),
                    ),

                    const SizedBox(height: 20),

                    _rotuloCampo('Senha'),

                    TextField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _decoracaoCampo(
                        'Digite a senha',
                      ).copyWith(
                        suffixIcon: TextButton(
                          onPressed: () {
                            setState(() {
                              _senhaVisivel = !_senhaVisivel;
                            });
                          },
                          child: Text(
                            _senhaVisivel ? 'Ocultar' : 'Ver',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _rotuloCampo('Confirmar senha'),

                    TextField(
                      controller: _confirmarSenhaController,
                      obscureText: !_senhaVisivel,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _decoracaoCampo(
                        'Confirmar senha',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Botão Criar conta
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _botaoHabilitado && !_carregando
                      ? _criarConta
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentDark,
                    disabledBackgroundColor:
                        AppColors.accentDark.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnDark,
                          ),
                        )
                      : const Text(
                          'Criar conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Link para login
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem uma conta? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    GestureDetector(
                      onTap: _irParaEntrar,
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}