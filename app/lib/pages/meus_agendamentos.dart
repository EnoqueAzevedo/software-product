import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'perfil.dart';
import 'servico.dart';

// Tela "Meus Agendamentos".
//
// Os dados vêm do banco através do ApiService. Esta tela espera estes métodos:
//
//   ApiService.getAgendamentosProximos()   -> List  (agendamentos futuros do usuário)
//   ApiService.getAgendamentosHistorico()  -> List  (agendamentos passados do usuário)
//   ApiService.cancelarAgendamento(id)     -> Future<void> (remove do banco;
//                                             lança exceção se falhar)
//
// Cada agendamento deve trazer: id, servico_nome, profissional_nome, data
// ('2026-10-25'), horario ('14:00'), imagem_url e, para o "Reagendar",
// servico_id.

// Largura máxima do conteúdo em telas largas
const double _larguraMaxima = 600;

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

// Pega o primeiro campo existente; se vier um objeto (ex.: {"nome": ...}) usa o nome
String _campo(dynamic item, List<String> chaves) {
  for (final chave in chaves) {
    final valor = item[chave];

    if (valor == null) continue;
    if (valor is Map) return (valor['nome'] ?? '').toString();

    final texto = valor.toString();
    if (texto.isNotEmpty) return texto;
  }

  return '';
}

// "2026-10-25" -> "25 de outubro de 2026"
String _dataExtenso(String texto) {
  final data = DateTime.tryParse(
    texto.length >= 10 ? texto.substring(0, 10) : texto,
  );

  if (data == null) return texto;

  return '${data.day} de ${_meses[data.month - 1]} de ${data.year}';
}

// "14:00:00" -> "14:00" (também aceita data e hora juntas: 2026-10-25T14:00:00)
String _hora(dynamic item) {
  var hora = _campo(item, ['horario', 'hora']);

  if (hora.isEmpty) {
    final data = _campo(item, ['data']);
    if (data.contains('T') && data.length >= 16) hora = data.substring(11, 16);
  }

  return hora.length > 5 ? hora.substring(0, 5) : hora;
}

String _urlImagem(dynamic caminho) {
  final texto = (caminho ?? '').toString();
  if (texto.isEmpty) return '';
  if (texto.startsWith('http')) return texto;
  return '${ApiService.baseUrl}$texto';
}

// Estado de cada aba (próximos / histórico)
class _EstadoAba {
  List<dynamic> itens = [];
  bool carregando = false;
  bool carregado = false;
  bool erro = false;
}

class MeusAgendamentosScreen extends StatefulWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  State<MeusAgendamentosScreen> createState() => _MeusAgendamentosScreenState();
}

class _MeusAgendamentosScreenState extends State<MeusAgendamentosScreen> {
  int _aba = 0; // 0 = Próximos Horários, 1 = Histórico
  final List<_EstadoAba> _estados = [_EstadoAba(), _EstadoAba()];

  dynamic _cancelandoId; // agendamento com cancelamento em andamento

  @override
  void initState() {
    super.initState();
    _carregar(0);
  }

  // Busca os agendamentos da aba no banco
  Future<void> _carregar(int aba, {bool forcar = false}) async {
    final estado = _estados[aba];

    if (estado.carregando) return;
    if (estado.carregado && !forcar) return;

    setState(() {
      estado.carregando = true;
      estado.erro = false;
    });

    try {
      final dados = aba == 0
          ? await ApiService.getAgendamentosProximos()
          : await ApiService.getAgendamentosHistorico();

      if (!mounted) return;

      setState(() {
        estado.itens = List<dynamic>.from(dados);
        estado.carregado = true;
        estado.carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        estado.carregando = false;
        estado.erro = true;
      });

      debugPrint('ERRO AO CARREGAR AGENDAMENTOS (aba $aba): $e');
    }
  }

  void _trocarAba(int aba) {
    if (aba == _aba) return;

    setState(() => _aba = aba);
    _carregar(aba);
  }

  // ir para tela iniciar
  void _irParaInicio() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  // Abre servico.dart; se o usuário agendar, recarrega a lista
  Future<void> _novoAgendamento() async {
    final agendou = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ServicoScreen()));

    if (agendou != true || !mounted) return;

    setState(() => _aba = 0);
    _carregar(0, forcar: true);
  }

  // Reagendar: abre servico.dart com o serviço já escolhido. Quando o novo
  // horário é confirmado, o agendamento antigo é removido.
  Future<void> _reagendar(dynamic agendamento) async {
    final antigoId = agendamento['id'];
    final servicoId = agendamento['servico_id'];

    final agendou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServicoScreen(
          servicoInicial: servicoId == null
              ? null
              : {
                  'id': servicoId,
                  'nome': _campo(agendamento, ['servico_nome', 'servico']),
                },
        ),
      ),
    );

    if (agendou != true || !mounted) return;

    String mensagem = 'Horário alterado com sucesso!';

    try {
      await ApiService.cancelarAgendamento(antigoId);
    } catch (e) {
      debugPrint('ERRO AO REMOVER AGENDAMENTO ANTIGO: $e');
      mensagem =
          'Novo horário agendado, mas não foi possível remover o antigo.';
    }

    if (!mounted) return;

    _mostrarMensagem(mensagem);
    _carregar(0, forcar: true);
  }

  // Cancelar: pergunta antes e, se confirmado, remove do banco
  Future<void> _cancelar(dynamic agendamento) async {
    final servico = _campo(agendamento, ['servico_nome', 'servico']);
    final data = _dataExtenso(_campo(agendamento, ['data']));
    final hora = _hora(agendamento);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DialogoCancelar(resumo: '$servico em $data às $hora'),
    );

    if (confirmou != true || !mounted) return;

    final id = agendamento['id'];

    setState(() => _cancelandoId = id);

    try {
      await ApiService.cancelarAgendamento(id);

      if (!mounted) return;

      setState(() {
        _estados[0].itens.removeWhere((a) => a['id'] == id);
        _cancelandoId = null;
      });

      _mostrarMensagem('Agendamento cancelado.');
    } catch (e) {
      debugPrint('ERRO AO CANCELAR AGENDAMENTO: $e');

      if (!mounted) return;

      setState(() => _cancelandoId = null);

      _mostrarMensagem('Não foi possível cancelar. Tente novamente.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: AppColors.accentDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final titulo = Theme.of(context).textTheme.cormorantTitle.copyWith(
      color: AppColors.textPrimary,
      fontSize: 32,
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
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => _carregar(_aba, forcar: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Meus Agendamentos',
                                      style: titulo,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const _BotaoSino(),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _Abas(
                                selecionada: _aba,
                                onSelecionar: _trocarAba,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildLista(),
                              if (_aba == 0) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _novoAgendamento,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 36,
                                        vertical: 16,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: const Text('Novo Agendamento +'),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                const _BannerIndicacao(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _BottomNavBar(onInicio: _irParaInicio, onNovo: _novoAgendamento),
            ],
          ),
        ),
      ),
    );
  }

  // Lista da aba atual conforme o estado (carregando / erro / vazio / itens)
  Widget _buildLista() {
    final estado = _estados[_aba];

    if (estado.carregando && !estado.carregado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (estado.erro) {
      return _MensagemErro(
        onTentarNovamente: () => _carregar(_aba, forcar: true),
      );
    }

    if (estado.itens.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text(
            _aba == 0
                ? 'Você ainda não tem horários agendados.'
                : 'Nenhum agendamento no histórico.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in estado.itens) ...[
          _AgendamentoCard(
            agendamento: item,
            mostrarAcoes: _aba == 0,
            ocupado: _cancelandoId != null && _cancelandoId == item['id'],
            onReagendar: () => _reagendar(item),
            onCancelar: () => _cancelar(item),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// Sino de notificações (igual ao da home)
class _BotaoSino extends StatelessWidget {
  const _BotaoSino();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.heroBackground,
          shape: BoxShape.circle,
        ),
        child: const Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textOnDark,
                size: 22,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: SizedBox(
                width: 9,
                height: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Abas "Próximos Horários" e "Histórico"
class _Abas extends StatelessWidget {
  const _Abas({required this.selecionada, required this.onSelecionar});

  final int selecionada;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AbaItem(
            texto: 'Próximos Horários',
            selecionada: selecionada == 0,
            onTap: () => onSelecionar(0),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AbaItem(
            texto: 'Histórico',
            selecionada: selecionada == 1,
            onTap: () => onSelecionar(1),
          ),
        ),
      ],
    );
  }
}

class _AbaItem extends StatelessWidget {
  const _AbaItem({
    required this.texto,
    required this.selecionada,
    required this.onTap,
  });

  final String texto;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: selecionada ? FontWeight.w600 : FontWeight.w400,
                color: selecionada
                    ? AppColors.accentDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: selecionada ? AppColors.accentDark : AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão de um agendamento
class _AgendamentoCard extends StatelessWidget {
  const _AgendamentoCard({
    required this.agendamento,
    required this.mostrarAcoes,
    required this.ocupado,
    required this.onReagendar,
    required this.onCancelar,
  });

  final dynamic agendamento;
  final bool mostrarAcoes; // false no histórico
  final bool ocupado; // cancelamento em andamento
  final VoidCallback onReagendar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final servico = _campo(agendamento, ['servico_nome', 'servico']);
    final profissional = _campo(agendamento, [
      'profissional_nome',
      'profissional',
    ]);
    final data = _dataExtenso(_campo(agendamento, ['data']));
    final hora = _hora(agendamento);
    final url = _urlImagem(
      agendamento['imagem_url'] ?? agendamento['servico_imagem_url'],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.beigeCard, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            servico,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: SizedBox(
                  width: 96,
                  height: 96,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Linha(
                      icone: Icons.person_outline_rounded,
                      texto: profissional,
                    ),
                    const SizedBox(height: 8),
                    _Linha(icone: Icons.calendar_month_outlined, texto: data),
                    const SizedBox(height: 8),
                    _Linha(icone: Icons.access_time_rounded, texto: hora),
                  ],
                ),
              ),
            ],
          ),
          if (mostrarAcoes) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BotaoAcao(
                    icone: Icons.sync_rounded,
                    texto: 'Reagendar',
                    onTap: ocupado ? null : onReagendar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BotaoAcao(
                    icone: Icons.delete_outline_rounded,
                    texto: 'Cancelar',
                    carregando: ocupado,
                    onTap: ocupado ? null : onCancelar,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Linha com ícone + texto (profissional, data, hora)
class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppColors.accentDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

// Botão "Reagendar" / "Cancelar" (contorno arredondado)
class _BotaoAcao extends StatelessWidget {
  const _BotaoAcao({
    required this.icone,
    required this.texto,
    required this.onTap,
    this.carregando = false,
  });

  final IconData icone;
  final String texto;
  final VoidCallback? onTap; // null = desativado
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.beigeCard, width: 1.5),
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentDark,
                  ),
                )
              : Icon(icone, size: 20, color: AppColors.accentDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// Pergunta "tem certeza?" antes de cancelar
class _DialogoCancelar extends StatelessWidget {
  const _DialogoCancelar({required this.resumo});

  final String resumo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      title: Text(
        'Cancelar agendamento?',
        style: Theme.of(context).textTheme.cormorantTitle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 26,
        ),
      ),
      content: Text(
        'Tem certeza de que deseja cancelar $resumo? '
        'Essa ação não pode ser desfeita.',
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
          child: const Text('Não'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentDark,
            foregroundColor: AppColors.textOnDark,
            textStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Sim, cancelar'),
        ),
      ],
    );
  }
}

// Faixa "Indique uma amiga"
class _BannerIndicacao extends StatelessWidget {
  const _BannerIndicacao();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.beigeCard.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard_rounded, size: 72, color: AppColors.accent),
          SizedBox(width: 20),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: 'Indique uma amiga\ne ganhe '),
                  TextSpan(
                    text: '10% de desconto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '\nno seu próximo serviço!'),
                ],
              ),
            ),
          ),
        ],
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
        size: 28,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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

// Barra de navegação inferior (como na imagem; "Agenda" fica em destaque)
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.onInicio, required this.onNovo});

  final VoidCallback onInicio;
  final VoidCallback onNovo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      // A barra ocupa a tela toda, mas os itens ficam juntos em telas largas
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
                onTap: onInicio,
              ),
              const _NavItem(icon: Icons.spa_outlined, label: 'Serviços'),
              InkWell(
                onTap: onNovo,
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
              ),
              const _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Agenda',
                selected: true,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PerfilScreen(),
                    ),
                  );
                },
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
    );
  }
}
