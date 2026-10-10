import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Tela "Agendar Horário".
//
// Os dados vêm do banco através do ApiService. Esta tela espera estes métodos:
//
//   ApiService.getServicos()        -> List  (já existe; usa id, nome, descricao,
//                                             preco, duracao, imagem_url)
//   ApiService.getProfissionais()   -> List  (id, nome, especialidade, foto_url)
//   ApiService.getHorarios(servicoId:, profissionalId:, data: 'AAAA-MM-DD')
//                                   -> List  (["09:00", ...] ou
//                                             [{"hora": "09:00", "disponivel": true}])
//   ApiService.criarAgendamento(servicoId:, profissionalId:, data:, horario:)
//                                   -> Future<void> (lança exceção se falhar)

// Largura máxima do conteúdo em telas largas
const double _larguraMaxima = 560;

const List<String> _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

// "15 de outubro de 2026"
String _dataExtenso(DateTime d) =>
    '${d.day} de ${_meses[d.month - 1]} de ${d.year}';

// "2026-10-15" (formato enviado para a API)
String _dataApi(DateTime d) {
  final mes = d.month.toString().padLeft(2, '0');
  final dia = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mes-$dia';
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Aceita URL completa ou caminho relativo vindo da API
String _urlImagem(dynamic caminho) {
  final texto = (caminho ?? '').toString();
  if (texto.isEmpty) return '';
  if (texto.startsWith('http')) return texto;
  return '${ApiService.baseUrl}$texto';
}

// Converte o valor da API (número ou texto) para "R$ 120,00"
String _formatarPreco(dynamic valor) {
  final numero = valor is num
      ? valor.toDouble()
      : double.tryParse('$valor'.replaceAll(',', '.')) ?? 0.0;

  return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _Horario {
  const _Horario({required this.hora, this.disponivel = true});

  final String hora;
  final bool disponivel;
}

_Horario _paraHorario(dynamic item) {
  String hora;
  bool disponivel = true;

  if (item is Map) {
    hora = '${item['hora'] ?? item['horario'] ?? ''}';
    disponivel = item['disponivel'] != false;
  } else {
    hora = '$item';
  }

  // "14:00:00" -> "14:00"
  if (hora.length > 5) hora = hora.substring(0, 5);

  return _Horario(hora: hora, disponivel: disponivel);
}

class ServicoScreen extends StatefulWidget {
  const ServicoScreen({super.key, this.servicoInicial});

  /// Serviço já escolhido (ex.: ao tocar em "Agendar" na home)
  final dynamic servicoInicial;

  @override
  State<ServicoScreen> createState() => _ServicoScreenState();
}

class _ServicoScreenState extends State<ServicoScreen> {
  dynamic _servico;
  dynamic _profissional;
  DateTime? _data;
  String? _horario;

  List<_Horario> _horarios = [];
  bool _carregandoHorarios = false;
  bool _erroHorarios = false;
  int _buscaId = 0; // evita que uma busca antiga sobrescreva a mais recente

  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _servico = widget.servicoInicial;
  }

  bool get _podeBuscarHorarios =>
      _servico != null && _profissional != null && _data != null;

  bool get _formularioCompleto => _podeBuscarHorarios && _horario != null;

  Future<T?> _abrirSheet<T>(Widget Function(BuildContext) builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: _larguraMaxima),
      builder: builder,
    );
  }

  // Abre a lista de serviços (buscada no banco a cada abertura)
  Future<void> _selecionarServico() async {
    final escolhido = await _abrirSheet<dynamic>(
      (context) => _SheetLista(
        titulo: 'Escolha o serviço',
        mensagemVazia: 'Nenhum serviço disponível.',
        carregar: () async => List<dynamic>.from(await ApiService.getServicos()),
        itemBuilder: (item, aoSelecionar) =>
            _ServicoTile(servico: item, onTap: aoSelecionar),
      ),
    );

    if (escolhido == null || !mounted) return;

    setState(() => _servico = escolhido);
    _buscarHorarios();
  }

  // Abre a lista de profissionais (buscada no banco a cada abertura)
  Future<void> _selecionarProfissional() async {
    final escolhido = await _abrirSheet<dynamic>(
      (context) => _SheetLista(
        titulo: 'Escolha o profissional',
        mensagemVazia: 'Nenhum profissional disponível.',
        carregar: () async =>
            List<dynamic>.from(await ApiService.getProfissionais()),
        itemBuilder: (item, aoSelecionar) =>
            _ProfissionalTile(profissional: item, onTap: aoSelecionar),
      ),
    );

    if (escolhido == null || !mounted) return;

    setState(() => _profissional = escolhido);
    _buscarHorarios();
  }

  // Abre o calendário
  Future<void> _selecionarData() async {
    final escolhida = await _abrirSheet<DateTime>(
      (context) => _CalendarioSheet(selecionada: _data),
    );

    if (escolhida == null || !mounted) return;

    setState(() => _data = escolhida);
    _buscarHorarios();
  }

  // Busca os horários livres para serviço + profissional + data
  Future<void> _buscarHorarios() async {
    if (!_podeBuscarHorarios) {
      _buscaId++;
      setState(() {
        _horarios = [];
        _horario = null;
        _carregandoHorarios = false;
        _erroHorarios = false;
      });
      return;
    }

    final id = ++_buscaId;

    setState(() {
      _horarios = [];
      _horario = null;
      _carregandoHorarios = true;
      _erroHorarios = false;
    });

    try {
      final dados = await ApiService.getHorarios(
        servicoId: _servico['id'],
        profissionalId: _profissional['id'],
        data: _dataApi(_data!),
      );

      if (!mounted || id != _buscaId) return;

      setState(() {
        _horarios = List<dynamic>.from(dados)
            .map(_paraHorario)
            .where((h) => h.hora.isNotEmpty)
            .toList();
        _carregandoHorarios = false;
      });
    } catch (e) {
      if (!mounted || id != _buscaId) return;

      setState(() {
        _carregandoHorarios = false;
        _erroHorarios = true;
      });

      debugPrint('ERRO AO CARREGAR HORÁRIOS: $e');
    }
  }

  Future<void> _confirmar() async {
    if (!_formularioCompleto || _enviando) return;

    setState(() => _enviando = true);

    try {
      await ApiService.criarAgendamento(
        servicoId: _servico['id'],
        profissionalId: _profissional['id'],
        data: _dataApi(_data!),
        horario: _horario!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento confirmado!'),
          backgroundColor: AppColors.accentDark,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _enviando = false);

      debugPrint('ERRO AO CONFIRMAR AGENDAMENTO: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível confirmar. Tente novamente.'),
          backgroundColor: AppColors.accentDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final titulo = Theme.of(context).textTheme.cormorantTitle.copyWith(
      color: AppColors.textPrimary,
      fontSize: 34,
      height: 1.1,
    );

    return MediaQuery(
      // Limita o aumento de fonte do sistema para o layout não quebrar
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _larguraMaxima,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                ),
                                color: AppColors.textPrimary,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Agendar Horário', style: titulo),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Escolha os detalhes do seu atendimento',
                              style: TextStyle(
                                fontSize: 15.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Serviço
                            const _Rotulo('Serviço'),
                            _CampoSelecao(
                              onTap: _selecionarServico,
                              child: _servico == null
                                  ? const _Placeholder('Selecione o serviço')
                                  : Text(
                                      (_servico['nome'] ?? 'Serviço').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Profissional
                            const _Rotulo('Profissional'),
                            _CampoSelecao(
                              onTap: _selecionarProfissional,
                              child: _profissional == null
                                  ? const _Placeholder('Selecione o profissional')
                                  : Row(
                                      children: [
                                        _Avatar(
                                          url: _urlImagem(
                                            _profissional['foto_url'],
                                          ),
                                          nome: (_profissional['nome'] ?? '')
                                              .toString(),
                                          diametro: 44,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (_profissional['nome'] ?? '')
                                                    .toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                (_profissional['especialidade'] ??
                                                        '')
                                                    .toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Data
                            const _Rotulo('Data'),
                            _CampoSelecao(
                              onTap: _selecionarData,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: AppColors.accent,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _data == null
                                        ? const _Placeholder('Selecione a data')
                                        : Text(
                                            _dataExtenso(_data!),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Horário
                            const _Rotulo('Horário'),
                            _buildHorarios(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Botão fixo no rodapé
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _larguraMaxima),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _formularioCompleto && !_enviando
                                ? _confirmar
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.accent
                                  .withValues(alpha: 0.45),
                              disabledForegroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _enviando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Confirmar Agendamento'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm + 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Seus dados estão seguros conosco',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Conteúdo da seção "Horário" conforme o estado
  Widget _buildHorarios() {
    const estiloDica = TextStyle(
      fontSize: 13.5,
      height: 1.3,
      color: AppColors.textSecondary,
    );

    if (!_podeBuscarHorarios) {
      return const Text(
        'Escolha o serviço, o profissional e a data para ver os horários.',
        style: estiloDica,
      );
    }

    if (_carregandoHorarios) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_erroHorarios) {
      return _MensagemErro(onTentarNovamente: _buscarHorarios);
    }

    if (_horarios.isEmpty) {
      return const Text('Nenhum horário disponível nesta data.', style: estiloDica);
    }

    // 3 colunas no celular, 4 em telas mais largas
    return LayoutBuilder(
      builder: (context, constraints) {
        const espaco = 10.0;
        final colunas = constraints.maxWidth >= 480 ? 4 : 3;
        final largura = (constraints.maxWidth - espaco * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final h in _horarios)
              SizedBox(
                width: largura,
                child: _HorarioChip(
                  horario: h,
                  selecionado: _horario == h.hora,
                  onTap: h.disponivel
                      ? () => setState(() => _horario = h.hora)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

// Título acima de cada campo
class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
    );
  }
}

// Campo que parece um dropdown e abre uma lista ao toque
class _CampoSelecao extends StatelessWidget {
  const _CampoSelecao({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(child: child),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.accentDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Botão de horário (livre, selecionado ou indisponível)
class _HorarioChip extends StatelessWidget {
  const _HorarioChip({
    required this.horario,
    required this.selecionado,
    required this.onTap,
  });

  final _Horario horario;
  final bool selecionado;
  final VoidCallback? onTap; // null = indisponível

  @override
  Widget build(BuildContext context) {
    final disponivel = onTap != null;

    return Material(
      color: selecionado
          ? AppColors.accent.withValues(alpha: 0.22)
          : AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        side: BorderSide(
          color: selecionado ? AppColors.accent : AppColors.divider,
          width: selecionado ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          alignment: Alignment.center,
          child: Text(
            horario.hora,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
              color: disponivel
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.6),
              decoration: disponivel ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

// Foto redonda do profissional (com a inicial se não houver foto)
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.nome, required this.diametro});

  final String url;
  final String nome;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final inicial = Center(
      child: Text(
        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.accentDark,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: diametro,
        height: diametro,
        child: ColoredBox(
          color: AppColors.beigeCard,
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => inicial,
                )
              : inicial,
        ),
      ),
    );
  }
}

class _ImagemIndisponivel extends StatelessWidget {
  const _ImagemIndisponivel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 26,
      ),
    );
  }
}

class _MensagemErro extends StatelessWidget {
  const _MensagemErro({required this.onTentarNovamente});

  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Não foi possível carregar. Verifique sua conexão.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onTentarNovamente,
            style: TextButton.styleFrom(foregroundColor: AppColors.accentDark),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listas que abrem ao tocar nos campos
// ---------------------------------------------------------------------------

// Moldura comum dos painéis que sobem de baixo
class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.beigeCard,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.cormorantTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

// Painel com lista buscada no banco (carregando / erro / vazio / itens)
class _SheetLista extends StatefulWidget {
  const _SheetLista({
    required this.titulo,
    required this.carregar,
    required this.itemBuilder,
    required this.mensagemVazia,
  });

  final String titulo;
  final Future<List<dynamic>> Function() carregar;
  final Widget Function(dynamic item, VoidCallback aoSelecionar) itemBuilder;
  final String mensagemVazia;

  @override
  State<_SheetLista> createState() => _SheetListaState();
}

class _SheetListaState extends State<_SheetLista> {
  late Future<List<dynamic>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      titulo: widget.titulo,
      child: FutureBuilder<List<dynamic>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('ERRO AO CARREGAR LISTA: ${snapshot.error}');

            return _MensagemErro(
              onTentarNovamente: () =>
                  setState(() => _futuro = widget.carregar()),
            );
          }

          final itens = snapshot.data ?? [];

          if (itens.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Text(
                  widget.mensagemVazia,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: itens.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm + 4),
            itemBuilder: (context, index) {
              final item = itens[index];

              return widget.itemBuilder(
                item,
                () => Navigator.of(context).pop(item),
              );
            },
          );
        },
      ),
    );
  }
}

// Cartão clicável usado nas listas
class _CardSelecionavel extends StatelessWidget {
  const _CardSelecionavel({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: child),
      ),
    );
  }
}

// Item da lista de serviços: foto, nome, descrição, preço e seta
class _ServicoTile extends StatelessWidget {
  const _ServicoTile({required this.servico, required this.onTap});

  final dynamic servico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nome = (servico['nome'] ?? 'Serviço').toString();
    final descricao = (servico['descricao'] ?? '').toString().trim();
    final subtitulo = descricao.isNotEmpty
        ? descricao
        : '${servico['duracao'] ?? 0} min';
    final url = _urlImagem(servico['imagem_url']);

    return _CardSelecionavel(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: SizedBox(
              width: 76,
              height: 76,
              child: ColoredBox(
                color: AppColors.beigeCard,
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ImagemIndisponivel(),
                      )
                    : const _ImagemIndisponivel(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarPreco(servico['preco']),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.accentDark),
        ],
      ),
    );
  }
}

// Item da lista de profissionais: foto, nome e especialidade
class _ProfissionalTile extends StatelessWidget {
  const _ProfissionalTile({required this.profissional, required this.onTap});

  final dynamic profissional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nome = (profissional['nome'] ?? '').toString();
    final especialidade = (profissional['especialidade'] ?? '').toString();

    return _CardSelecionavel(
      onTap: onTap,
      child: Row(
        children: [
          _Avatar(
            url: _urlImagem(profissional['foto_url']),
            nome: nome,
            diametro: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (especialidade.isNotEmpty)
                  Text(
                    especialidade,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendário (em português, sem depender de pacotes ou de localização)
// ---------------------------------------------------------------------------

class _CalendarioSheet extends StatefulWidget {
  const _CalendarioSheet({this.selecionada});

  final DateTime? selecionada;

  @override
  State<_CalendarioSheet> createState() => _CalendarioSheetState();
}

class _CalendarioSheetState extends State<_CalendarioSheet> {
  late final DateTime _hoje;
  late final DateTime _primeiroMes;
  late final DateTime _ultimoMes;
  late DateTime _mes; // primeiro dia do mês exibido

  @override
  void initState() {
    super.initState();

    final agora = DateTime.now();
    _hoje = DateTime(agora.year, agora.month, agora.day);
    _primeiroMes = DateTime(_hoje.year, _hoje.month);
    _ultimoMes = DateTime(_hoje.year, _hoje.month + 12); // até 12 meses à frente

    final base = widget.selecionada ?? _hoje;
    _mes = DateTime(base.year, base.month);
  }

  void _mudarMes(int delta) {
    final novo = DateTime(_mes.year, _mes.month + delta);

    if (novo.isBefore(_primeiroMes) || novo.isAfter(_ultimoMes)) return;

    setState(() => _mes = novo);
  }

  @override
  Widget build(BuildContext context) {
    final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final espacosVazios = DateTime(_mes.year, _mes.month, 1).weekday - 1;
    final nomeMes = _meses[_mes.month - 1];
    final tituloMes =
        '${nomeMes[0].toUpperCase()}${nomeMes.substring(1)} ${_mes.year}';

    return _SheetContainer(
      titulo: 'Escolha a data',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _mes.isAfter(_primeiroMes)
                      ? () => _mudarMes(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.accentDark,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      tituloMes,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _mes.isBefore(_ultimoMes)
                      ? () => _mudarMes(1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.accentDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final dia in _diasSemana)
                  Expanded(
                    child: Center(
                      child: Text(
                        dia,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < espacosVazios; i++) const SizedBox.shrink(),
                for (var dia = 1; dia <= diasNoMes; dia++) _celulaDia(dia),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _celulaDia(int dia) {
    final data = DateTime(_mes.year, _mes.month, dia);
    final passado = data.isBefore(_hoje);
    final selecionado =
        widget.selecionada != null && _mesmoDia(widget.selecionada!, data);
    final ehHoje = _mesmoDia(data, _hoje);

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: passado ? null : () => Navigator.of(context).pop(data),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selecionado ? AppColors.accent : null,
          border: ehHoje && !selecionado
              ? Border.all(color: AppColors.accent)
              : null,
        ),
        child: Text(
          '$dia',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: selecionado || ehHoje
                ? FontWeight.w700
                : FontWeight.w500,
            color: selecionado
                ? Colors.white
                : passado
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
