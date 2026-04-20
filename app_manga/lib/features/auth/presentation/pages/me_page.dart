import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'auth_page.dart';
import '../../../manga/presentation/pages/home_page.dart';
import '../../../manga/presentation/pages/search_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Me'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: auth.isBusy ? null : auth.refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: profile == null
          ? Center(
              child: Text(
                auth.errorMessage ?? 'Khong tai duoc thong tin user',
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFFF6B00),
                    backgroundImage: (profile.avatar != null && profile.avatar!.startsWith('http'))
                        ? NetworkImage(profile.avatar!)
                        : null,
                    child: (profile.avatar == null || !profile.avatar!.startsWith('http'))
                        ? Text(
                            (profile.fullName ?? 'U').trim().isEmpty
                                ? 'U'
                                : (profile.fullName!.trim().substring(0, 1).toUpperCase()),
                            style: const TextStyle(fontSize: 28, color: Color(0xFF222222)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.fullName ?? auth.session?.userName ?? 'Reader',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: profile.isPremium ? const Color(0xFFFFE3CC) : const Color(0xFFE4E4E4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      profile.isPremium ? 'Premium' : 'Standard',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: profile.isPremium ? const Color(0xFFB34B09) : const Color(0xFF555555),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InfoCard(
                    rows: [
                      _InfoRow(label: 'Username', value: auth.session?.userName ?? '-'),
                      _InfoRow(label: 'Email', value: profile.email ?? '-'),
                      _InfoRow(label: 'Phone', value: profile.phone ?? '-'),
                      _InfoRow(label: 'Gender', value: profile.gender ?? '-'),
                      _InfoRow(label: 'Birth', value: profile.birth ?? '-'),
                      _InfoRow(label: 'Address', value: profile.address ?? '-'),
                      _InfoRow(label: 'Role', value: auth.session?.role ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: const Color(0xFF222222),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Dang xuat'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: const Color(0xFFE8742B),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        row.label,
                        style: const TextStyle(color: Color(0xFF616161)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}
