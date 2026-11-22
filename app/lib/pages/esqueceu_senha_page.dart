import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';

class EsqueceuSenhaScreen extends StatefulWidget {
  const EsqueceuSenhaScreen({super.key});

  @override
  State<EsqueceuSenhaScreen> createState() => _EsqueceuSenhaScreenState();
}

class _EsqueceuSenhaScreenState extends State<EsqueceuSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();
    if (email.isEmpty) return 'Informe seu e-mail';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'E-mail inválido';
    return null;
  }

  
  
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      await ApiService.solicitarRecuperacao(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.mark_email_read_outlined,
              size: 52,
              color: AppColors.accent,
            ),
            title: const Text(
              'Verifique seu e-mail!',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Se existir uma conta associada ao endereço informado, '
              'você receberá as instruções para redefinir sua senha.\n\n'
              'Abra sua caixa de entrada e procure o e-mail do Agenda Pulcro. '
              'Caso não encontre, verifique também a pasta de spam.\n\n'
              'O link de recuperação expira em 30 minutos e só pode ser '
              'utilizado uma vez.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
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

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar a solicitação.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide.none,
    );
    final bordaErro = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: const BorderSide(color: Colors.redAccent),
    );

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
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      'Esqueceu a senha',
                      textAlign: TextAlign.center,
                      style: textTheme.cormorantTitle.copyWith(
                        fontSize: 36,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      'Por favor, insira o e-mail associado à sua conta\n'
                      'e enviaremos um e-mail de verificação',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.6,
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
                          Text('E-mail', style: textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.sm + 2),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: _validarEmail,
                            onFieldSubmitted: (_) => _enviar(),
                            style: textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'ex: maria@clinica.com',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                              ),
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
                      onPressed: _carregando ? null : _enviar,
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
                          : const Text('Enviar'),
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
