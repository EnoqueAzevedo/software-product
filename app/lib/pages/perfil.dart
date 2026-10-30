import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'meus_agendamentos.dart';
import 'servico.dart';

const double _larguraMaximaPerfil = 720;

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Uint8List? _fotoBytes;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);


  // O cropper funciona na web, no Android e no iOS (não existe para desktop).
  bool get _suportaRecorte => kIsWeb || _isMobile;

  Future<void> _escolherImagem(ImageSource origem) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (imagem == null || !mounted) return;

      // No desktop não há recorte: usa a imagem inteira.
      final Uint8List? bytes = _suportaRecorte
          ? await _recortarImagem(imagem.path)
          : await imagem.readAsBytes();

      if (bytes == null || !mounted) return;

      setState(() => _fotoBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível carregar a imagem.');
      debugPrint('Erro ao escolher imagem: $e');
    }
  }

  Future<Uint8List?> _recortarImagem(String caminho) async {
    final recortada = await ImageCropper().cropImage(
      sourcePath: caminho,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar imagem',
          toolbarColor: Colors.purple,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Recortar imagem'),
        WebUiSettings(context: context),
      ],
    );

    if (recortada == null) return null; // usuário cancelou

    return recortada.readAsBytes(); // funciona também na web
  }

  

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _abrirOpcoesFoto() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isMobile)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Câmera'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _escolherImagem(ImageSource.camera);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _escolherImagem(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _fotoBytes = null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemMenu({
    required IconData icone,
    required String titulo,
    VoidCallback? onTap,
  }) {
    return Card(
      color: AppColors.background,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.grey),
      ),
      child: ListTile(
        leading: Icon(icone, size: 28),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 17),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      // Mantém o mesmo limite de escala de texto utilizado na Home.
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    // Em telas largas, limita e centraliza o conteúdo do Perfil,
                    // como acontece no HomeScreen.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _larguraMaximaPerfil,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          24,
                          AppSpacing.md,
                          24,
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: _fotoBytes != null
                                      ? MemoryImage(_fotoBytes!)
                                      : null,
                                  child: _fotoBytes == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 65,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Material(
                                    color: AppColors.cardBackground,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      tooltip: 'Alterar foto',
                                      onPressed: _abrirOpcoesFoto,
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.pink,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Enoque',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _itemMenu(
                              icone: Icons.account_circle_outlined,
                              titulo: 'Meus dados',
                            ),
                            _itemMenu(
                              icone: Icons.calendar_month_outlined,
                              titulo: 'Meus Horários',
                            ),
                            _itemMenu(
                              icone: Icons.favorite_border,
                              titulo: 'Favoritos',
                            ),
                            _itemMenu(
                              icone: Icons.local_offer_outlined,
                              titulo: 'Cupons',
                            ),
                            _itemMenu(
                              icone: Icons.help_outline,
                              titulo: 'Ajuda e Suporte',
                            ),
                            const SizedBox(height: 48),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: OutlinedButton(
                                onPressed: () {
                                  // Implementar o encerramento da sessão.
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  foregroundColor: Colors.purple,
                                  side: const BorderSide(color: Colors.purple),
                                ),
                                child: const Text(
                                  'Sair',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const _BottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }
}

// Barra inferior com o mesmo padrão visual da Home e de Meus Agendamentos.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Início',
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              _NavItem(
                icon: Icons.spa_outlined,
                label: 'Serviços',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServicoScreen(),
                    ),
                  );
                },
              ),
              _NavFabItem(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServicoScreen(),
                    ),
                  );
                },
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Agenda',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MeusAgendamentosScreen(),
                    ),
                  );
                },
              ),
              const _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                selected: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavFabItem extends StatelessWidget {
  const _NavFabItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
