import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/children_screen.dart';
import '../screens/child_form_screen.dart';
import '../screens/event_form_screen.dart';
import '../screens/photo_form_screen.dart';
import '../screens/parameter_form_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/timeline_detail_screen.dart';
import '../screens/growth_screen.dart';
import '../screens/photo_gallery_screen.dart';
import '../screens/photo_viewer_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'children',
            builder: (context, state) => const ChildrenScreen(),
          ),
          GoRoute(
            path: 'child/add',
            builder: (context, state) => const ChildFormScreen(),
          ),
          GoRoute(
            path: 'child/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChildFormScreen(childId: id);
            },
          ),
          GoRoute(
            path: 'event/add',
            builder: (context, state) => const EventFormScreen(),
          ),
          GoRoute(
            path: 'event/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EventFormScreen(eventId: id);
            },
          ),
          GoRoute(
            path: 'photo/add',
            builder: (context, state) => const PhotoFormScreen(),
          ),
          GoRoute(
            path: 'photo/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PhotoFormScreen(photoId: id);
            },
          ),
          GoRoute(
            path: 'parameter/add',
            builder: (context, state) => const ParameterFormScreen(),
          ),
          GoRoute(
            path: 'parameter/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ParameterFormScreen(parameterId: id);
            },
          ),
          GoRoute(
            path: 'timeline/:type/:id',
            builder: (context, state) {
              final type = state.pathParameters['type']!;
              final id = state.pathParameters['id']!;
              return TimelineDetailScreen(type: type, id: id);
            },
          ),
          GoRoute(
            path: 'growth',
            builder: (context, state) => const GrowthScreen(),
          ),
          GoRoute(
            path: 'photos',
            builder: (context, state) => const PhotoGalleryScreen(),
          ),
          GoRoute(
            path: 'photo/viewer/:index',
            builder: (context, state) {
              final index =
                  int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
              return PhotoViewerScreen(initialIndex: index);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
