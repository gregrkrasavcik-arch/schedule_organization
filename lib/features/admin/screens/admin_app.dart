import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_screen.dart';
import 'analytics_screen.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const AdminScreen(),
            const AnalyticsScreen(),
            _buildDataManagementScreen(),
            _buildSettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDataManagementScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('📊 Управление данными'),
          floating: true,
          pinned: true,
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildManagementCard(
                '👥 Группы',
                'Управление группами студентов',
                Icons.groups,
                Colors.blue,
                () {},
              ),
              const SizedBox(height: 12),
              _buildManagementCard(
                '🎓 Преподаватели',
                'Управление преподавателями',
                Icons.school,
                Colors.green,
                () {},
              ),
              const SizedBox(height: 12),
              _buildManagementCard(
                '📚 Предметы',
                'Управление дисциплинами',
                Icons.book,
                Colors.orange,
                () {},
              ),
              const SizedBox(height: 12),
              _buildManagementCard(
                '👤 Студенты',
                'Управление студентами',
                Icons.person,
                Colors.purple,
                () {},
              ),
              const SizedBox(height: 12),
              _buildManagementCard(
                '🏫 Программы обучения',
                'Управление образовательными программами',
                Icons.layers,
                Colors.red,
                () {},
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.7),
                            color.withOpacity(1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('⚙️ Настройки'),
          floating: true,
          pinned: true,
          backgroundColor: Colors.grey.shade100,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingsSection('Система'),
              _buildSettingsTile('Язык', 'Русский', Icons.language),
              _buildSettingsTile('Тема', 'Светлая', Icons.brightness_5),
              _buildSettingsTile(
                'Уведомления',
                'Включены',
                Icons.notifications,
              ),
              const SizedBox(height: 24),
              _buildSettingsSection('Профиль'),
              _buildSettingsTile(
                'Мой аккаунт',
                'admin@college.com',
                Icons.account_circle,
              ),
              _buildSettingsTile(
                'Безопасность',
                'Изменить пароль',
                Icons.security,
              ),
              const SizedBox(height: 24),
              _buildSettingsSection('Другое'),
              _buildSettingsTile('О приложении', 'v1.0.0', Icons.info),
              _buildSettingsTile('Справка', 'Документация', Icons.help),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.2),
                          Colors.red.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Выход',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade600),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Панель',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Аналитика',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storage),
                label: 'Данные',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Настройки',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
