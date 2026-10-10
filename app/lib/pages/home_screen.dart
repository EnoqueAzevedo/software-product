import 'dart:convert';

import 'package:flutter/material.dart';

import 'servico.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// Largura máxima do conteúdo: em tablets e telas largas ele fica centralizado
const double _larguraMaxima = 720;

// Página inicial aberta depois do login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nomeUsuario = 'Carregando...';

  List<dynamic> servicos = [];
  bool carregandoServicos = true;

  @override
  void initState() {
    super.initState();

    _carregarUsuario();
    _carregarServicos();
  }

  // Busca os dados do usuário autenticado
  Future<void> _carregarUsuario() async {
    try {
      final resposta = await ApiService.getMe();

      final dados = jsonDecode(resposta);

      if (!mounted) return;

      setState(() {
        nomeUsuario = dados['nome'] ?? 'Usuário';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        nomeUsuario = 'Usuário';
      });

      print('ERRO AO CARREGAR USUÁRIO: $e');
    }
  }

  // Busca os serviços cadastrados no banco
  Future<void> _carregarServicos() async {
    try {
      final dados = await ApiService.getServicos();

      if (!mounted) return;

      setState(() {
        servicos = dados;
        carregandoServicos = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoServicos = false;
      });

      print('ERRO AO CARREGAR SERVIÇOS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

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
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HomeHeader(nomeUsuario: nomeUsuario),
                            const SizedBox(height: AppSpacing.md),
                            const _Tagline(),
                            const SizedBox(height: AppSpacing.md),
                            const _HeroCard(),
                            const SizedBox(height: AppSpacing.lg),
                            _ServicesList(
                              servicos: servicos,
                              carregando: carregandoServicos,
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

// Cabeçalho com usuário e notificações
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.nomeUsuario});

  final String nomeUsuario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor:
              AppColors.beigeCard, // aparece se a imagem não carregar
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=47'),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bom dia,',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                nomeUsuario.isNotEmpty
                    ? '${nomeUsuario[0].toUpperCase()}${nomeUsuario.substring(1)}'
                    : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.cormorantTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          background: AppColors.heroBackground,
          iconColor: AppColors.textOnDark,
          onTap: () {},
          showBadge: true,
        ),
      ],
    );
  }
}

// Botão circular do cabeçalho
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: iconColor, size: 22)),
            if (showBadge)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Frase logo abaixo do cabeçalho
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Flexible(
          child: Text(
            'Beleza que cabe na sua rotina',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Icon(Icons.favorite_border_rounded, color: AppColors.accent, size: 22),
      ],
    );
  }
}

// Card principal de destaque: foto ocupando o card todo, com degradê rosado
// à esquerda para dar leitura ao texto
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.cormorantTitle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        // Altura e fontes crescem com a largura, dentro de limites
        final altura = (largura / 1.9).clamp(200.0, 340.0).toDouble();
        final fonteTitulo = (largura * 0.095).clamp(30.0, 52.0).toDouble();
        final fonteSubtitulo = (largura * 0.048).clamp(16.0, 24.0).toDouble();

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: SizedBox(
            height: altura,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo que aparece se a foto não carregar
                const ColoredBox(color: AppColors.heroBackgroundLight),
                Image.asset(
                  'assets/images/home.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
                // Degradê da esquerda (mais forte) para a direita (transparente)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.heroBackgroundLight.withValues(alpha: 0.95),
                        AppColors.accent.withValues(alpha: 0.70),
                        AppColors.accent.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 0.85],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cuide de você',
                        style: titulo.copyWith(
                          fontSize: fonteSubtitulo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Hoje e\nsempre',
                        style: titulo.copyWith(
                          fontSize: fonteTitulo,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Ver ofertas'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Lista vertical de serviços vindos da API
class _ServicesList extends StatelessWidget {
  const _ServicesList({required this.servicos, required this.carregando});

  final List<dynamic> servicos;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (servicos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Nenhum serviço disponível.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // 1 coluna no celular, 2 colunas em telas mais largas (tablet/paisagem)
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth >= 640 ? 2 : 1;
        final larguraCard =
            (constraints.maxWidth - AppSpacing.md * (colunas - 1)) / colunas;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final servico in servicos)
              SizedBox(
                width: larguraCard,
                child: _ServiceCard(servico: servico),
              ),
          ],
        );
      },
    );
  }
}

// Card individual de serviço: foto à esquerda, textos e preço à direita
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.servico});

  final dynamic servico;

  @override
  Widget build(BuildContext context) {
    final String nome = servico['nome'] ?? 'Serviço';

    // Usa a descrição se a API enviar; senão mostra a duração
    final String descricao = (servico['descricao'] ?? '').toString().trim();
    final String subtitulo = descricao.isNotEmpty
        ? descricao
        : '${servico['duracao'] ?? 0} min';

    final String preco = _formatarPreco(servico['preco']);

    // Preço antigo (riscado) só aparece se a API enviar 'preco_original'
    final String? precoOriginal = servico['preco_original'] != null
        ? _formatarPreco(servico['preco_original'])
        : null;

    final String imagemUrl = servico['imagem_url'] != null
        ? '${ApiService.baseUrl}${servico['imagem_url']}'
        : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.beigeCard.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: SizedBox(
              width: 88,
              height: 88,
              child: ColoredBox(
                color: AppColors.beigeCard,
                child: imagemUrl.isNotEmpty
                    ? Image.network(
                        imagemUrl,
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
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            preco,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentDark,
                            ),
                          ),
                          if (precoOriginal != null)
                            Text(
                              precoOriginal,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () { //chama a pagina servico
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ServicoScreen()), // Nome da classe dentro de servico.dart
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentDark,
                        foregroundColor: AppColors.textOnDark,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: const Text('Agendar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ícone mostrado quando o serviço não tem foto ou ela falha ao carregar
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

// Converte o valor da API (número ou texto) para o formato "R$ 150,00"
String _formatarPreco(dynamic valor) {
  final numero = valor is num
      ? valor.toDouble()
      : double.tryParse('$valor'.replaceAll(',', '.')) ?? 0.0;

  return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
}

// Barra de navegação inferior
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

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
              const _NavItem(
                icon: Icons.home_rounded,
                label: 'Início',
                selected: true,
              ),
              const _NavItem(icon: Icons.spa_outlined, label: 'Serviços'),
              _NavFabItem(onTap: () {}),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Agenda',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServicoScreen()),
                  );
                },
              ),
              const _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Item da navegação inferior
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap, // 1. Adicionado o parâmetro opcional de clique
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap; // 2. Definido o callback

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentDark : AppColors.textSecondary;


    // 3. Envolvido com InkWell para torná-lo clicável
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

// Botão central para novo agendamento
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
