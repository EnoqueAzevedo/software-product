
//import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';


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

  Future<void> _selecionarGaleria() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null) return;

    final bytes = result.files.single.bytes;

    if (bytes == null) {
      _mostrarMensagem('Não foi possível carregar a imagem.');
      return;
    }

    setState(() {
      _fotoBytes = bytes;
    });
  }

  Future<void> _tirarFoto() async {
    try {
      final foto = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (foto == null || !mounted) return;

      final bytes = await foto.readAsBytes();

      if (!mounted) return;

      setState(() {
        _fotoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível acessar a câmera.');
      debugPrint('Erro ao capturar foto: $e');
    }
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
                    leading: const Icon(
                      Icons.photo_camera_outlined,
                    ),
                    title: const Text('Câmera'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _tirarFoto();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _selecionarGaleria();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _fotoBytes = null;
                    });
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: OutlinedButton(
                  onPressed: () {
                    // Implementar o encerramento da sessão.
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      48,
                    ),
                    foregroundColor: Colors.purple,
                    side: const BorderSide(
                      color: Colors.purple,
                    ),
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
    );
  }
}
