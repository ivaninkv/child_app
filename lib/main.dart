import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/notification_service.dart';
import 'presentation/router/app_router.dart';
import 'presentation/bloc/app/app_bloc.dart';
import 'presentation/bloc/children/children_bloc.dart';
import 'presentation/bloc/timeline/timeline_bloc.dart';
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/photos/photos_bloc.dart';
import 'presentation/bloc/parameters/parameters_bloc.dart';
import 'presentation/bloc/reminders/reminders_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  runApp(const ChildApp());
}

class ChildApp extends StatelessWidget {
  const ChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AppBloc()..add(AppInitialize())),
        BlocProvider(create: (context) => ChildrenBloc()..add(ChildrenLoad())),
        BlocProvider(create: (context) => TimelineBloc()),
        BlocProvider(create: (context) => EventsBloc()),
        BlocProvider(create: (context) => PhotosBloc()),
        BlocProvider(create: (context) => ParametersBloc()),
        BlocProvider(create: (context) => RemindersBloc()),
      ],
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Child App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
