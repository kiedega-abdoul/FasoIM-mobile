import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'fasoim_logo.dart';

class PublicPageScaffold extends StatelessWidget {
  const PublicPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: const Row(
          children: [
            FasoImLogo(compact: true),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.list(
                children: [
                  body,
                  const SizedBox(height: 28),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
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
          'Plateforme nationale de gestion des sessions d’immersion patriotique.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Unité, civisme et engagement au service de la Nation.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
