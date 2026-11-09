import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'meus_agendamentos.dart';
import 'servico.dart';
import 'recortar_foto_screen.dart';
import '../services/api_service.dart';

const double _larguraMaximaPerfil = 720;

const List<String> _opcoesGenero = [
  'Feminino',
  'Masculino',
  'Prefiro não dizer',
];

/// Tela "Informações Pessoais" (substitui a antiga tela de Perfil).
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController  = TextEditingController();
  
  bool _carregando = true;
  bool _salvando = false;
  String? _imagemUrl;

  Uint8List? _fotoBytes;
  String? _genero;
  DateTime? _dataNascimento;


  @override
  void initState(){
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final usuarioJson = await ApiService.getMe();
      final usuario = jsonDecode(usuarioJson) as Map<String, dynamic>;

      final perfil = await ApiService.getPerfil();

      if (!mounted) return;

      setState(() {
        _nomeController.text = usuario['nome'] ?? '';
        _telefoneController.text = perfil['telefone'] ?? '';

        final genero = perfil['genero'];

        _genero = _opcoesGenero.contains(genero) ? genero : null;

        final nascimento = perfil['data_nascimento'];

        _dataNascimento = nascimento != null
            ? DateTime.tryParse(nascimento)
            : null;

        _imagemUrl = perfil['imagem_url'];
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      _mostrarMensagem('Não foi possível carregar seus dados.');
      debugPrint('Erro ao carregar perfil: $e');
    }
  }

  Future<void> _abrirCameraFlutuante() async {
    try {
      final imagem = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CameraDialog(),
      );

      if (imagem == null || !mounted) return;

      final bytes = await RecortarFotoScreen.abrir(context, imagem);

      if (bytes == null || !mounted) return;

      setState(() => _fotoBytes = bytes);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível acessar a câmera.');
      debugPrint('Erro ao abrir câmera: $e');
    }
  }

  Future<void> _escolherImagem(ImageSource origem) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: origem,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (imagem == null || !mounted) return;

      final original = await imagem.readAsBytes();
      if (!mounted) return;

      final Uint8List? bytes =
          await RecortarFotoScreen.abrir(context, original);

      if (bytes == null || !mounted) return;

      setState(() => _fotoBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível carregar a imagem.');
      debugPrint('Erro ao escolher imagem: $e');
    }
  }

  Future<void> _abrirOpcoesFoto() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _abrirCameraFlutuante();
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
                    setState(() {
                      _fotoBytes = null;
                      _imagemUrl = null;
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

  // ------------------------------------------------------ Data de nascimento

  Future<void> _escolherData() async {
    FocusScope.of(context).unfocus();

    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      // Calendário em português (exige o setup de localização no MaterialApp).
      locale: const Locale('pt', 'BR'),
      initialDate: _dataNascimento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: agora,
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      builder: (context, child) {
        final tema = Theme.of(context);

        return Theme(
          data: tema.copyWith(
            colorScheme: tema.colorScheme.copyWith(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentDark,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (data == null || !mounted) return;

    setState(() => _dataNascimento = data);
  }

  // ------------------------------------------------------------- Ações

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);

    try {
      // 1) Se escolheu uma foto nova, envia primeiro e recebe a URL.
      String? imagemUrl = _imagemUrl;

      if (_fotoBytes != null) {
        imagemUrl = await ApiService.enviarFotoPerfil(_fotoBytes!);
      }

      // 2) Salva os dados no perfil (foto removida => imagemUrl null).
      final perfil = await ApiService.atualizarPerfil(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        genero: _genero,
        dataNascimento:
            _dataNascimento?.toIso8601String().split('T').first,
        imagemUrl: imagemUrl,
      );

      if (!mounted) return;

      setState(() {
        _imagemUrl = perfil['imagem_url'] as String? ?? imagemUrl;
        _fotoBytes = null;
      });

      await _mostrarTelaSucesso();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível salvar. Tente novamente.');
      debugPrint('Erro ao salvar perfil: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _mostrarTelaSucesso() async {
    // Exibe o diálogo de sucesso
    showDialog(
      context: context,
      barrierDismissible: false, // Impede o usuário de fechar clicando fora
      builder: (dialogContext) {
        return PopScope(
          canPop: false, // Impede o botão "voltar" de fechar o diálogo
          child: Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent, // Cor do seu tema
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dados atualizados!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Aguarda 2 segundos
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Fecha o diálogo
    Navigator.of(context).pop();

    // Redireciona para a Home limpando toda a pilha de navegação
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false, 
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // ------------------------------------------------------------ Widgets

  TextStyle get _estiloCampo => Theme.of(context).textTheme.bodyLarge!;

  TextStyle get _estiloDica =>
      _estiloCampo.copyWith(color: AppColors.textSecondary);

  InputDecoration _decoracao({String? hint, IconData? icone}) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    final erro = Theme.of(context).colorScheme.error;

    return InputDecoration(
      hintText: hint,
      hintStyle: _estiloDica,
      prefixIcon:
          icone != null ? Icon(icone, color: AppColors.textSecondary) : null,
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: borda(AppColors.divider),
      enabledBorder: borda(AppColors.divider),
      focusedBorder: borda(AppColors.accent, 1.5),
      errorBorder: borda(erro),
      focusedErrorBorder: borda(erro, 1.5),
    );
  }

  Widget _rotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _abrirOpcoesFoto,
            child: CircleAvatar(
              radius: 62,
              backgroundColor: AppColors.accent,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.background,
                backgroundImage: _fotoBytes != null
                    ? MemoryImage(_fotoBytes!)
                    : (_imagemUrl != null ? NetworkImage(_imagemUrl!) : null),
                child: (_fotoBytes == null && _imagemUrl == null)
                    ? const Icon(
                        Icons.person,
                        size: 65,
                        color: AppColors.beigeCard,
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Tooltip(
              message: 'Alterar foto',
              child: Material(
                color: AppColors.cardBackground,
                elevation: 2,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.accent),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _abrirOpcoesFoto,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 20,
                      color: AppColors.accentDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final dataTexto = _dataNascimento == null
        ? null
        : MaterialLocalizations.of(context).formatCompactDate(_dataNascimento!);

    return MediaQuery(
      // Mantém o mesmo limite de escala de texto utilizado na Home.
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Informações Pessoais',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: SafeArea(
          child: _carregando
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _larguraMaximaPerfil,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _avatar(),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Nome
                                  _rotulo('Nome'),
                                  TextFormField(
                                    controller: _nomeController,
                                    style: _estiloCampo,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: _decoracao(
                                      hint: 'Seu nome',
                                      icone: Icons.person_outline_rounded,
                                    ),
                                    validator: (valor) {
                                      if (valor == null || valor.trim().isEmpty) {
                                        return 'Informe seu nome.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Telefone
                                  _rotulo('Telefone'),
                                  TextFormField(
                                    controller: _telefoneController,
                                    style: _estiloCampo,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      _TelefoneInputFormatter(),
                                    ],
                                    decoration: _decoracao(
                                      hint: '(11) 99999-9999',
                                      icone: Icons.phone_outlined,
                                    ),
                                    validator: (valor) {
                                      final telefone = valor?.replaceAll(RegExp(r'\D'), '') ?? '';

                                      if (telefone.length != 10 && telefone.length != 11) {
                                        return 'Informe um telefone válido.';
                                      }

                                      return null;
                                    },
                                  ),
                                  
                                  
                                  
                                  const SizedBox(height: AppSpacing.lg),

                                  // Gênero
                                  _rotulo('Gênero'),
                                  InputDecorator(
                                    decoration: _decoracao(),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _genero,
                                        isExpanded: true,
                                        isDense: true,
                                        hint: Text('Gênero', style: _estiloDica),
                                        style: _estiloCampo,
                                        dropdownColor: AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.small,
                                        ),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.textSecondary,
                                        ),
                                        items: _opcoesGenero
                                            .map(
                                              (g) => DropdownMenuItem<String>(
                                                value: g,
                                                child: Text(g),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (valor) {
                                          setState(() => _genero = valor);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // Data de nascimento
                                  _rotulo('Data de Nascimento'),
                                  InkWell(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.small),
                                    onTap: _escolherData,
                                    child: InputDecorator(
                                      decoration: _decoracao(),
                                      child: Text(
                                        dataTexto ?? 'DD/MM/AAAA',
                                        style: dataTexto == null
                                            ? _estiloDica
                                            : _estiloCampo,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // Atualizar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _salvando ? null : _salvar,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: _salvando
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Atualizar'),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // Cancelar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.maybePop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accentDark,
                                        side: const BorderSide(
                                          color: AppColors.beigeCard,
                                        ),
                                        shape: const StadiumBorder(),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('Cancelar'),
                                    ),
                                  ),
                                ],
                              ),
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

class _CameraDialog extends StatefulWidget {
  const _CameraDialog();

  @override
  State<_CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<_CameraDialog> {
  CameraController? _controller;

  bool _carregando = true;
  bool _capturando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Nenhuma câmera encontrada.');
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível acessar a câmera.';
        _carregando = false;
      });
    }
  }

  Future<void> _tirarFoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _capturando) {
      return;
    }

    setState(() => _capturando = true);

    try {
      final arquivo = await controller.takePicture();
      final bytes = await arquivo.readAsBytes();

      if (!mounted) return;

      Navigator.of(context).pop(bytes);
    } catch (e) {
      if (!mounted) return;

      setState(() => _capturando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao tirar foto.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: const Text(
                'Tirar foto',
                style: TextStyle(fontSize: 18),
              ),
            ),

            // Visualização da câmera
            if (_carregando)
              const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erro != null)
              SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _erro!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),

            // Botões
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  FloatingActionButton(
                    heroTag: 'capturarFoto',
                    backgroundColor: AppColors.accent,
                    onPressed:
                        _carregando || _erro != null || _capturando
                            ? null
                            : _tirarFoto,
                    child: _capturando
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                  ),

                  const SizedBox(width: 65),
                ],
              ),
            ),
          ],
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


class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var numeros = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numeros.length > 11) {
      numeros = numeros.substring(0, 11);
    }

    if (numeros.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatado;

    if (numeros.length <= 2) {
      formatado = '($numeros';
    } else {
      final ddd = numeros.substring(0, 2);
      final telefone = numeros.substring(2);

      final divisao = numeros.length > 10 ? 5 : 4;

      if (telefone.length <= divisao) {
        formatado = '($ddd) $telefone';
      } else {
        formatado =
            '($ddd) ${telefone.substring(0, divisao)}-${telefone.substring(divisao)}';
      }
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(
        offset: formatado.length,
      ),
    );
  }
}