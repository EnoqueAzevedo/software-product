import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';


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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      nomeUsuario: nomeUsuario,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _HeroCard(),
                    const SizedBox(height: AppSpacing.md),
                    const _NextAppointmentCard(),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(
                      title: 'Serviços populares',
                      actionLabel: 'Ver todos',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PopularServicesGrid(
                      servicos: servicos,
                      carregando: carregandoServicos,
                    ),
                  ],
                ),
              ),
            ),
            const _BottomNavBar(),
          ],
        ),
      ),
    );
  }
}


// Cabeçalho com usuário, busca e notificações
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.nomeUsuario,
  });

  final String nomeUsuario;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.beigeCard, // ser a imagem nao carregar 
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?img=47',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bom dia,',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                nomeUsuario.isNotEmpty
                    ? '${nomeUsuario[0].toUpperCase()}${nomeUsuario.substring(1)}'
                    : '',
                style: Theme.of(context).textTheme.cormorantTitle?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
              )
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.search,
          background: AppColors.cardBackground,
          iconColor: AppColors.textPrimary,
          onTap: () {},
        ),
        const SizedBox(width: AppSpacing.sm),
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
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            if (showBadge)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
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


// Card principal de destaque
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.heroBackground,
            AppColors.heroBackgroundLight,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      AppRadius.pill,
                    ),
                  ),
                  child: const Text(
                    'Studio',
                    style: TextStyle(
                      color: AppColors.textOnDarkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Seu momento de\ncuidado começa aqui',
                  style: Theme.of(context).textTheme.cormorantTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver rituais'),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppRadius.medium,
            ),
            child: Image.network(
              'https://images.unsplash.com/photo-1600334129128-685c5582fd35?w=400',
              width: 96,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}


// Card com o próximo horário
class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.beigeCard,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.accentDark,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo horário',
                  style: TextStyle(
                    color: AppColors.accentDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Qui 18 · 15:30 — Massagem\nrelaxante',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sm,
            ),
            child: Text(
              'Detalhes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Título de uma seção
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
  });

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            color: AppColors.accentDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}


// Lista de serviços vindos da API
class _PopularServicesGrid extends StatelessWidget {
  const _PopularServicesGrid({
    required this.servicos,
    required this.carregando,
  });

  final List<dynamic> servicos;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (servicos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Nenhum serviço disponível.',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: servicos.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final servico = servicos[index];

        return _ServiceCard(
          servico: servico,
        );
      },
    );
  }
}


// Card individual de serviço
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.servico,
  });

  final dynamic servico;

  @override
  Widget build(BuildContext context) {
    final String nome = servico['nome'] ?? 'Serviço';
    final String duracao = '${servico['duracao'] ?? 0} min';
    final String preco = 'R\$ ${servico['preco'] ?? 0}';

    final String imagemUrl = servico['imagem_url'] != null
        ? '${ApiService.baseUrl}${servico['imagem_url']}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(
          AppRadius.large,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: imagemUrl.isNotEmpty
                ? Image.network(
                    imagemUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              8,
              10,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconeDoServico(nome),
                      size: 14,
                      color: AppColors.accentDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duracao,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      preco,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
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


  // Escolhe um ícone de acordo com o serviço
  IconData _iconeDoServico(String nome) {
    final nomeNormalizado = nome.toLowerCase();

    if (nomeNormalizado.contains('limpeza')) {
      return Icons.spa_rounded;
    }

    if (nomeNormalizado.contains('massagem')) {
      return Icons.local_fire_department_rounded;
    }

    if (nomeNormalizado.contains('sobrancelha')) {
      return Icons.remove_red_eye_outlined;
    }

    if (nomeNormalizado.contains('manicure')) {
      return Icons.back_hand_outlined;
    }

    return Icons.spa_rounded;
  }
}


// Barra de navegação inferior
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _NavItem(
            icon: Icons.home_rounded,
            label: 'Início',
            selected: true,
          ),
          const _NavItem(
            icon: Icons.spa_outlined,
            label: 'Serviços',
          ),
          _NavFabItem(
            onTap: () {},
          ),
          const _NavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Agenda',
          ),
          const _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Perfil',
          ),
        ],
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
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accentDark
        : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 22,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}


// Botão central para novo agendamento
class _NavFabItem extends StatelessWidget {
  const _NavFabItem({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: InkWell(
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
                color: AppColors.accent.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}