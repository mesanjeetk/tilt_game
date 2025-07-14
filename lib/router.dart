import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/pyq_page.dart';
import 'pages/year_pdf_page.dart';
import 'pages/important_questions_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => Scaffold(body: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/pyqs',
          builder: (context, state) => const PYQPage(),
        ),
        GoRoute(
          path: '/pyqs/:year',
          builder: (context, state) {
            final year = state.pathParameters['year']!;
            return YearPDFPage(year: year);
          },
        ),
        GoRoute(
          path: '/important',
          builder: (context, state) => const ImportantQuestionsPage(),
        ),
      ],
    ),
  ],
);
