import 'package:flutter/material.dart';
import 'login_page.dart'; // Ajuste o caminho se o seu main.dart estiver em outra pasta

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailTelefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _validarEmail(String email) {
    final regex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );
    return regex.hasMatch(email);
  }
  bool _validarTelefone(String telefone) {
    // Remove espaços, parênteses, hífens etc.
    final numeros = telefone.replaceAll(RegExp(r'\D'), '');
    // Considerando telefone brasileiro:
    // 10 números = telefone fixo
    // 11 números = celular
    return numeros.length == 10 || numeros.length == 11;
  }

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


  bool _senhaVisivel = false;
  bool _botaoHabilitado = false;

  static const Color corPrincipal = Color(0xFF7CC144);

  @override
  void initState() {
    super.initState();
    _nomeController.addListener(_validarCampos);
    _emailTelefoneController.addListener(_validarCampos);
    _senhaController.addListener(_validarCampos);
    _confirmarSenhaController.addListener(_validarCampos);
  }
  
  void _validarCampos() {
    final nome = _nomeController.text.trim();
    final contato = _emailTelefoneController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    // Nome: mínimo de 3 caracteres
    final nomeValido = nome.length >= 3;

    // E-mail ou telefone válido
    final contatoValido = _validarEmail(contato) || _validarTelefone(contato);

    // Senha: mínimo de 6 caracteres
    final senhaValida = senha.length >= 6 &&
        !_temTresNumerosConsecutivos(senha);

    // Confirmação da senha
    final senhasIguais =
        confirmarSenha.isNotEmpty && senha == confirmarSenha;

    final formularioValido =
        nomeValido &&
        contatoValido &&
        senhaValida &&
        senhasIguais;

    if (formularioValido != _botaoHabilitado) {
      setState(() {
        _botaoHabilitado = formularioValido;
    });
  }
}

  void _criarConta() {
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta criada com sucesso!')),
    );
  }

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
    _emailTelefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  InputDecoration _decoracaoCampo(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _rotuloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
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
                      color: corPrincipal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Colors.white,
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
                        ),
                      ),
                      Text(
                        'Organize seu dia com simplicidade',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
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
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Crie sua conta para seus compromissos',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Cartão com o formulário
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotuloCampo('Nome Completo'),
                    TextField(
                      controller: _nomeController,
                      decoration: _decoracaoCampo('Digite seu nome completo'),
                    ),
                    const SizedBox(height: 20),

                    _rotuloCampo('E-mail ou Telefone'),
                    TextField(
                      controller: _emailTelefoneController,
                      decoration: _decoracaoCampo(
                          'ex: maria@clinica.com ou (11) 98765-4321'),
                    ),
                    const SizedBox(height: 20),

                    _rotuloCampo('Senha'),
                    TextField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      decoration: _decoracaoCampo('Digite a senha').copyWith(
                        suffixIcon: TextButton(
                          onPressed: () {
                            setState(() {
                              _senhaVisivel = !_senhaVisivel;
                            });
                          },
                          child: Text(
                            _senhaVisivel ? 'Ocultar' : 'Ver',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _rotuloCampo('Confirmar senha'),
                    TextField(
                      controller: _confirmarSenhaController,
                      obscureText: !_senhaVisivel,
                      decoration: _decoracaoCampo('Confirmar senha'),
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
                  onPressed: _botaoHabilitado ? _criarConta : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    disabledBackgroundColor: corPrincipal.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      style: TextStyle(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: _irParaEntrar,
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: corPrincipal,
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
