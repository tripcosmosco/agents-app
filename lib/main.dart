import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/ai_agent_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/event_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/website_radar_provider.dart';
import 'providers/whatsapp_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'widgets/app_security_lock_gate.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Crash Prevention & White Screen Guard
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0B132B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_problem_rounded, color: Color(0xFFF59E0B), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Data Sync Notice',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Set system navigation & status bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B132B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final apiService = ApiService();
  await apiService.initPreferences();
  await NotificationService().init();

  runApp(XAgentsApp(apiService: apiService));
}

class XAgentsApp extends StatelessWidget {
  final ApiService? apiService;

  const XAgentsApp({super.key, this.apiService});

  @override
  Widget build(BuildContext context) {
    final service = apiService ?? ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => CallProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => LeadProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => AiAgentProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => WhatsAppProvider(apiService: service),
        ),
        ChangeNotifierProvider(
          create: (_) => WebsiteRadarProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CatalogProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp(
            title: AppConstants.appFullName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: authProvider.isAuthenticated
                ? AppSecurityLockGate(
                    child: MainNavigationScreen(apiService: service),
                  )
                : LoginScreen(
                    onLoginSuccess: () {},
                  ),
          );
        },
      ),
    );
  }
}
