import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class AlterarSenhaScreen extends StatefulWidget {
  /// Token recebido por e-mail (opcional), enviado ao backend ao alterar.
  final String? token;

  const AlterarSenhaScreen({super.key, this.token});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _ocultarNova = true;
  bool _ocultarConfirmar = true;
  bool _carregando = false;

  @override
  void dispose() {
    _novaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String? _validarNova(String? valor) {
    final senha = valor ?? '';
    if (senha.isEmpty) return 'Informe a nova senha';
    if (senha.length < 8) return 'Use pelo menos 8 caracteres';
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Confirme a nova senha';
    if (valor != _novaController.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _alterar() async {
    if (!_formKey.currentState!.validate()) return;

    // Recuperação exige o token recebido por e-mail.
    if (widget.token != null && widget.token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link de recuperação inválido.'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      if (widget.token != null) {
        final mensagem = await ApiService.redefinirSenha(
          token: widget.token!,
          novaSenha: _novaController.text,
          confirmarSenha: _confirmarController.text,
        );

        if (!mounted) return;

        // Mostra o dialog de sucesso
        await _mostrarDialogSucesso(mensagem);

        // Depois de fechar o dialog, volta para a home
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alteração de senha ainda não configurada.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível alterar a senha. Verifique o link e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _mostrarDialogSucesso(String mensagem) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.lock_reset,
            size: 52,
            color: AppColors.accent,
          ),
          title: const Text(
            'Senha alterada',
            textAlign: TextAlign.center,
          ),
          content: Text(
            mensagem.isNotEmpty
                ? mensagem
                : 'Sua senha foi alterada com sucesso.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnDark,
                minimumSize: const Size(140, 45),
              ),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Widget _rotulo(TextTheme textTheme, String texto) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 10),
        child: Text(texto, style: textTheme.titleMedium),
      );

  InputDecoration _decoracao({
    required TextTheme textTheme,
    required String hint,
    required bool oculto,
    required VoidCallback alternar,
  }) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide.none,
    );
    final bordaErro = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: const BorderSide(color: Colors.redAccent),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: textTheme.bodyMedium?.copyWith(fontSize: 15),
      filled: true,
      fillColor: AppColors.pillBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 18,
      ),
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda,
      errorBorder: bordaErro,
      focusedErrorBorder: bordaErro,
      suffixIcon: IconButton(
        onPressed: alternar,
        icon: Icon(
          oculto ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 160,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.face_retouching_natural,
                        size: 120,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Alterar Senha',
                      textAlign: TextAlign.center,
                      style: textTheme.cormorantTitle.copyWith(
                        fontSize: 38,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Crie uma nova senha para sua conta.\n'
                      'Certifique-se de que ela seja forte e segura.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rotulo(textTheme, 'Nova Senha'),
                          TextFormField(
                            controller: _novaController,
                            obscureText: _ocultarNova,
                            validator: _validarNova,
                            textInputAction: TextInputAction.next,
                            style: textTheme.bodyLarge,
                            decoration: _decoracao(
                              textTheme: textTheme,
                              hint: 'Digite Nova Senha',
                              oculto: _ocultarNova,
                              alternar: () =>
                                  setState(() => _ocultarNova = !_ocultarNova),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _rotulo(textTheme, 'Confirmar Nova Senha'),
                          TextFormField(
                            controller: _confirmarController,
                            obscureText: _ocultarConfirmar,
                            validator: _validarConfirmacao,
                            onFieldSubmitted: (_) => _alterar(),
                            style: textTheme.bodyLarge,
                            decoration: _decoracao(
                              textTheme: textTheme,
                              hint: 'Confirmar Nova Senha',
                              oculto: _ocultarConfirmar,
                              alternar: () => setState(
                                  () => _ocultarConfirmar = !_ocultarConfirmar),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _alterar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textOnDark,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textOnDark,
                              ),
                            )
                          : const Text('Alterar Senha'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    label: Text(
                      'Voltar para o login',
                      style: textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
