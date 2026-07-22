import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fasoim_logo.dart';

class PublicHomePage extends StatefulWidget {
  const PublicHomePage({super.key});

  @override
  State<PublicHomePage> createState() => _PublicHomePageState();
}

class _PublicHomePageState extends State<PublicHomePage> {
  static const _backgroundImages = <String>[
    'assets/images/immersion_01.png',
    'assets/images/immersion_02.png',
    'assets/images/immersion_03.png',
    'assets/images/immersion_04.png',
    'assets/images/immersion_05.png',
  ];

  int _currentImage = 0;
  Timer? _timer;
  bool _remainingImagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _currentImage = (_currentImage + 1) % _backgroundImages.length;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_remainingImagesPrecached) return;
    _remainingImagesPrecached = true;

    // Laisse le premier écran s'afficher avant de charger les autres images.
    // Cela évite un blocage visible au démarrage sur les téléphones modestes.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final path in _backgroundImages.skip(1)) {
        if (!mounted) return;
        await precacheImage(AssetImage(path), context);
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goTo(String route) => Navigator.pushNamed(context, route);

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu FasoIM',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.manage_search_rounded,
                  title: 'Consulter mon immersion',
                  onTap: () {
                    Navigator.pop(context);
                    _goTo('/consultation');
                  },
                ),
                _MenuItem(
                  icon: Icons.assignment_outlined,
                  title: 'Demande volontaire',
                  onTap: () {
                    Navigator.pop(context);
                    _goTo('/volunteer');
                  },
                ),
                _MenuItem(
                  icon: Icons.verified_outlined,
                  title: 'Vérifier une attestation',
                  onTap: () {
                    Navigator.pop(context);
                    _goTo('/certificate');
                  },
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'À propos de FasoIM',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FasoIM facilite la consultation et le suivi de l’immersion patriotique.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(
                imagePath: _backgroundImages[_currentImage],
                currentImage: _currentImage,
                imageCount: _backgroundImages.length,
                onMenu: _openMenu,
                onConsult: () => _goTo('/consultation'),
                onVolunteer: () => _goTo('/volunteer'),
                onCertificate: () => _goTo('/certificate'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Vos services essentiels',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Accédez rapidement aux principaux services publics FasoIM.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ServiceCard(
                    icon: Icons.manage_search_rounded,
                    title: 'Consulter mon immersion',
                    description:
                        'Recherchez votre dossier avec votre numéro de PV, votre récépissé, votre matricule ou votre code FasoIM.',
                    onTap: () => _goTo('/consultation'),
                  ),
                  const SizedBox(height: 14),
                  _ServiceCard(
                    icon: Icons.assignment_outlined,
                    title: 'Faire une demande volontaire',
                    description:
                        'Consultez les sessions ouvertes et déposez votre demande d’immersion volontaire.',
                    onTap: () => _goTo('/volunteer'),
                  ),
                  const SizedBox(height: 14),
                  _ServiceCard(
                    icon: Icons.verified_outlined,
                    title: 'Vérifier une attestation',
                    description:
                        'Vérifiez une attestation FasoIM par code ou par QR code.',
                    onTap: () => _goTo('/certificate'),
                  ),
                  const SizedBox(height: 28),
                  const _PublicInfoBanner(),
                  const SizedBox(height: 28),
                  const _HomeFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.imagePath,
    required this.currentImage,
    required this.imageCount,
    required this.onMenu,
    required this.onConsult,
    required this.onVolunteer,
    required this.onCertificate,
  });

  final String imagePath;
  final int currentImage;
  final int imageCount;
  final VoidCallback onMenu;
  final VoidCallback onConsult;
  final VoidCallback onVolunteer;
  final VoidCallback onCertificate;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth < 380 ? 500.0 : 470.0;
    final imageCacheWidth = (screenWidth * MediaQuery.devicePixelRatioOf(context)).round();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
          child: Row(
            children: [
              const FasoImLogo(compact: true),
              const Spacer(),
              IconButton(
                tooltip: 'Ouvrir le menu',
                onPressed: onMenu,
                color: AppColors.primaryDark,
                iconSize: 32,
                icon: const Icon(Icons.menu_rounded),
              ),
            ],
          ),
        ),
        SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 850),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: Image.asset(
                  imagePath,
                  key: ValueKey(imagePath),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  cacheWidth: imageCacheWidth,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x5000140B),
                      Color(0xB500331C),
                      Color(0xF2003E22),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Text(
                        'IMMERSION PATRIOTIQUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Préparez et suivez votre immersion patriotique en toute simplicité',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.07,
                            letterSpacing: -0.5,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Consultez votre affectation, déposez une demande volontaire ou vérifiez une attestation FasoIM.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onConsult,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      icon: const Icon(Icons.manage_search_rounded),
                      label: const Text('Consulter mon immersion'),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onVolunteer,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(49),
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0x6600331C),
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text(
                              'Demande volontaire',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCertificate,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(49),
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0x6600331C),
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text(
                              'Vérifier attestation',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageCount,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentImage == index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentImage == index ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicInfoBanner extends StatelessWidget {
  const _PublicInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE4D6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service public sécurisé',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Utilisez uniquement vos propres informations pour consulter un dossier, suivre une demande ou vérifier une attestation.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontSize: 13.5,
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

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.border),
        SizedBox(height: 14),
        Text(
          'FasoIM',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Plateforme nationale de gestion des sessions d’immersion patriotique au Burkina Faso.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        SizedBox(height: 6),
        Text(
          'Unité, civisme et engagement au service de la Nation.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        SizedBox(height: 18),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
