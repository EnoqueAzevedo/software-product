//import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Tela de enquadramento no estilo do WhatsApp.
/// Devolve os bytes da imagem recortada (quadrada) ou null se cancelar.
class RecortarFotoScreen extends StatefulWidget {
  const RecortarFotoScreen({super.key, required this.imagem});

  final Uint8List imagem;

  /// Atalho: abre a tela e retorna o resultado.
  static Future<Uint8List?> abrir(BuildContext context, Uint8List imagem) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RecortarFotoScreen(imagem: imagem),
      ),
    );
  }

  @override
  State<RecortarFotoScreen> createState() => _RecortarFotoScreenState();
}

class _RecortarFotoScreenState extends State<RecortarFotoScreen> {
  static const _fundo = Color(0xFF0B141A);
  static const _verde = Color(0xFF25D366);

  final _controller = CropController();
  late Uint8List _bytes;
  int _versao = 0; // muda a key do Crop ao girar, reiniciando o enquadramento
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _bytes = widget.imagem;
  }

  Future<void> _girar() async {
    setState(() => _ocupado = true);
    try {
      final girada = await compute(_girar90, _bytes);
      if (!mounted) return;
      setState(() {
        _bytes = girada;
        _versao++;
      });
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _confirmar() {
    setState(() => _ocupado = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Crop(
                    key: ValueKey(_versao),
                    image: _bytes,
                    controller: _controller,
                    aspectRatio: 1, // quadrado,
                    interactive: false, // nao permite mover e dar zoom na imagem
                    baseColor: _fundo,
                    maskColor: Colors.black.withValues(alpha: 0.6),
                    initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                      size: 0.9,
                      aspectRatio: 1,
                    ),
                    progressIndicator:
                        const CircularProgressIndicator(color: _verde),
                    onCropped: (result) {
                      switch (result) {
                        case CropSuccess(:final croppedImage):
                          Navigator.of(context).pop(croppedImage);

                        case CropFailure():
                          if (!mounted) return;

                          setState(() => _ocupado = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Não foi possível recortar.'),
                            ),
                          );
                      }
                    },
                  ),
                  if (_ocupado)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: CircularProgressIndicator(color: _verde),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Barra inferior: Cancelar | girar | OK
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _ocupado ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: _verde, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Girar',
                    onPressed: _ocupado ? null : _girar,
                    icon: const Icon(Icons.rotate_90_degrees_ccw_outlined,
                        color: Colors.white, size: 28),
                  ),
                  TextButton(
                    onPressed: _ocupado ? null : _confirmar,
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: _verde,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Função top-level (exigida pelo compute) que gira a imagem 90°.
Uint8List _girar90(Uint8List bytes) {
  final original = img.decodeImage(bytes);
  if (original == null) return bytes;
  final girada = img.copyRotate(original, angle: -90);
  return Uint8List.fromList(img.encodeJpg(girada, quality: 92));
}
