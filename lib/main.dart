import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/models/lesson.dart';
import 'data/models/day_schedule.dart';
import 'data/models/full_schedule.dart';
import 'data/models/note.dart';
import 'data/providers/app_state.dart';
import 'data/providers/notes_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/text_size_provider.dart';
import 'data/services/notification_service.dart';
import 'features/start_view/start_screen.dart';
import 'features/schedule_list/schedule_page.dart';
import 'features/note_list/note_page.dart';
import 'features/settings_list/settings_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LessonAdapter());
  Hive.registerAdapter(DayScheduleAdapter());
  Hive.registerAdapter(FullScheduleAdapter());
  Hive.registerAdapter(NoteAdapter());

  await NotificationService.initialize();

  final appState = AppState();
  await appState.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TextSizeProvider()),
      ],
      child: MyApp(appState: appState),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'StudentApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const StartScreen(),
            '/home': (context) => const SchedulePage(),
            '/notes': (context) => const NotePage(),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}
