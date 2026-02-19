import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Littlewin'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Littlewin!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Temporary verify Supabase connection logic
                // This would normally check current session
                final session = Supabase.instance.client.auth.currentSession;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(session != null ? 'Logged In' : 'Not Logged In')),
                );
              },
              child: const Text('Check Auth Status'),
            ),
          ],
        ),
      ),
    );
  }
}
