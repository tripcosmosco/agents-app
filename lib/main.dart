import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/ai_agent_provider.dart';
import 'providers/call_provider.dart';
import 'providers/event_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/whatsapp_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/app_security_lock_gate.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appFullName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AppSecurityLockGate(
              child: MainNavigationScreen(apiService: service),
            ),
          );
        },
      ),
    );
  }
}
