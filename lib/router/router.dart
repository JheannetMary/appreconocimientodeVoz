import 'package:appmovil/screens/home.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ///* Auth Routes
    // GoRoute(
    //   path: '/home',
    //   builder: (context, state) => MyMap(),
    // ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const home(),
    ),
  ],
);
