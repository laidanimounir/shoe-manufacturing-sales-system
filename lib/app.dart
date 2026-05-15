import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/l10n/app_localizations.dart';
import 'features/settings/providers/settings_provider.dart';

class ShoeTrakApp extends StatelessWidget {
  const ShoeTrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppInitializer();
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(localSettingsProvider.notifier).init();
    return const AppBody();
  }
}

class AppBody extends ConsumerWidget {
  const AppBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(localSettingsProvider);

    return MaterialApp.router(
      title: 'ShoeTrak',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
