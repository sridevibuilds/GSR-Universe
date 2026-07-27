// Reusable Widget - Sidebar Navigation Drawer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../localization/app_translations.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? subtext;
  final String avatarUrl;
  final bool showProfileCard;
  final List<DrawerItem> items;
  final VoidCallback? onLogout;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    this.subtext,
    this.avatarUrl = 'assets/images/avatar.png',
    this.showProfileCard = false,
    required this.items,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: Column(
        children: [
          // 1. Sidebar Header (User Profile Card removed by default)
          if (showProfileCard)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: AssetImage(avatarUrl),
                  ),
                  AppSpacing.h12,
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    userRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (subtext != null) ...[
                    AppSpacing.h4,
                    Text(
                      subtext!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "GSR UNIVERSE",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Navigation items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  dense: true,
                  leading: Icon(item.icon, color: AppColors.gradientStart),
                  title: Text(
                    item.title.tr(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    item.onTap();
                  },
                );
              },
            ),
          ),

          // 3. Bottom logout action
          const Divider(color: AppColors.borderLight, height: 1.0),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text(
                  "Logout".tr(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                    fontSize: 14,
                  ),
                ),
                onTap: onLogout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
