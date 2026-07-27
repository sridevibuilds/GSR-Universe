// Reusable Widget - Responsive Custom AppBar
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String academicYear;
  final String profileName;
  final String profileRole;
  final String? profileSub; // e.g., "Class 7 - A"
  final String avatarUrl;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const CustomAppBar({
    super.key,
    this.title = "PIPPARA E.M. HIGH SCHOOL",
    this.academicYear = "2024 - 2025",
    required this.profileName,
    required this.profileRole,
    this.profileSub,
    this.avatarUrl = 'assets/images/avatar.png',
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.gradientStart),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 32,
          ),
        ],
      ),
      actions: [
        // 1. Notification bell icon with counting bubble
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                size: 24,
                color: AppColors.textDark,
              ),
              onPressed: onNotificationTap ??
                  () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
            ),
            if (notificationCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.w4,

        // 2. Avatar profile frame
        GestureDetector(
          onTap: onProfileTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.borderLight,
                backgroundImage: AssetImage(avatarUrl),
              ),
              if (isTablet) ...[
                AppSpacing.w8,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      profileSub != null ? "$profileRole • $profileSub" : profileRole,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textLight),
                AppSpacing.w8,
              ] else ...[
                AppSpacing.w8,
              ]
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.borderLight,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
