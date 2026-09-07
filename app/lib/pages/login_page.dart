import 'package:flutter/material.dart';
import 'cadastro_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _keepConnected = true;

  static const Color primaryGreen = Color(0xFF6FCF3B);
  static const Color darkText = Color(0xFF1F2937);
  static const Color greyText = Color(0xFF6B7280);
  static const Color fieldFill = Color(0xFFF3F4F6);

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildWelcomeSection(),
              const SizedBox(height: 28),
              _buildFormCard(),
              const SizedBox(height: 20),
              _buildGuestSection(),
              const SizedBox(height: 20),
              _buildNotificationCard(),
              const SizedBox(height: 20),
              _buildTermsText(),
            ],
          ),
        ),
      ),
    );
  }

  // Logo + nome do app
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assignment_turned_in_outlined,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AgendaFácil',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              Text(
                'Organize seu dia com simplicidade',
                style: TextStyle(fontSize: 13, color: greyText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Texto de boas-vindas + ilustração
  Widget _buildWelcomeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo de volta!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Acesse sua agenda e gerenciamento de compromissos',
                style: TextStyle(fontSize: 14, color: greyText, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildIllustration(),
      ],
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 90,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(Icons.mail_outline, color: primaryGreen.withValues(alpha: 0.5), size: 32),
          ),
          Positioned(
            left: 10,
            bottom: 20,
            child: Icon(Icons.mail_outline, color: primaryGreen, size: 26),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 46,
              height: 70,
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card com o formulário de login
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E-mail ou Telefone',
              style: TextStyle(fontSize: 14, color: darkText, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _loginController,
            hint: 'ex: maria@clinica.com ou (11) 98765-4321',
          ),
          const SizedBox(height: 18),
          const Text('Senha',
              style: TextStyle(fontSize: 14, color: darkText, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _passwordController,
                  hint: 'Digite sua senha',
                  obscure: _obscurePassword,
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Text(
                  _obscurePassword ? 'Ver' : 'Ocultar',
                  style: const TextStyle(color: darkText, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: _keepConnected,
                    activeThumbColor: primaryGreen,
                    onChanged: (v) => setState(() => _keepConnected = v),
                  ),
                  const Text('Manter-se conectado',
                      style: TextStyle(fontSize: 13, color: darkText)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Esqueceu a senha',
                        style: TextStyle(fontSize: 12, color: greyText)),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Alterar a senha',
                        style: TextStyle(
                            fontSize: 13,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
                elevation: 0,
              ),
              child: const Text('Entrar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldFill,
        borderRadius: BorderRadius.circular(26),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: darkText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: greyText),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // "Ainda não tem conta?" + criar conta
  Widget _buildGuestSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Ainda não tem conta?',
        style: TextStyle(
          fontSize: 13,
          color: greyText,
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CadastroPage(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: const Text(
            'Criar conta',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}

  // Card de permissão de notificações
  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ativar notificações',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkText)),
                SizedBox(height: 2),
                Text('Receba lembretes e confirmações de compromissos',
                    style: TextStyle(fontSize: 12, color: greyText)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: greyText),
        ],
      ),
    );
  }

  Widget _buildTermsText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Ao continuar, você concorda com os termos de uso e a política de privacidade da AgendaFácil.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: greyText, height: 1.4),
      ),
    );
  }
}
