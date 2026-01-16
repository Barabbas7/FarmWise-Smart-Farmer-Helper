import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/components/reusable_card.dart';
import '../ui/theme.dart';
import '../main.dart'; // To access FarmWiseApp.themeNotifier

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
             // Header
             Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/300'), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('John Doe',
                      style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  Text('Smallholder Farmer',
                      style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // App Settings
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("App Settings", style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  ReusableCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                         SwitchListTile(
                          title: const Text('Dark Theme'),
                          secondary: const Icon(Icons.dark_mode),
                          activeColor: AppTheme.primaryGreen,
                          value: isDark,
                          onChanged: (val) {
                            FarmWiseApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          trailing: const Text('English', style: TextStyle(color: Colors.grey)),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifications'),
                          trailing: Switch(
                            value: true, 
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (_){}
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account
                   Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Account", style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                   ReusableCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                          onTap: () async {
                              await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  Text('Version 1.0.0', style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
