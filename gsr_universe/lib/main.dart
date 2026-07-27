// Application Entry Point
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/localization/language_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/login_cubit.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';
import 'features/faculty/presentation/cubit/faculty_cubit.dart';
import 'features/parent/presentation/cubit/parent_cubit.dart';

// Global Key for programmatic context-less navigation routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 [CRASH_LOCATION] Exception: ${details.exception}');
    debugPrint('🔴 [CRASH_LOCATION] StackTrace:\n${details.stack}');
  };

  // Initialize dependency injection mappings
  await di.init();
  
  // Register session expired 401 callback hook
  ApiClient.onSessionExpired = () {
    // Trigger local token erasure
    di.sl<AuthCubit>().logout();
    
    // Force transition back to login page clearing history
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(
          create: (_) => LanguageCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => di.sl<AuthCubit>(),
        ),
        BlocProvider<LoginCubit>(
          create: (_) => di.sl<LoginCubit>(),
        ),
        BlocProvider<AdminCubit>(
          create: (_) => di.sl<AdminCubit>(),
        ),
        BlocProvider<FacultyCubit>(
          create: (_) => di.sl<FacultyCubit>(),
        ),
        BlocProvider<ParentCubit>(
          create: (_) => di.sl<ParentCubit>(),
        ),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'GSR Universe ERP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('te', 'IN'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            navigatorKey: navigatorKey,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
