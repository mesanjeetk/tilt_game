import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Previous Year Questions'),
              onPressed: () => context.go('/pyqs'),
            ),
            ElevatedButton(
              child: const Text('Important Questions'),
              onPressed: () => context.go('/important'),
            ),
          ],
        ),
      ),
    );
  }
}
