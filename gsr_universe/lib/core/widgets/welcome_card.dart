// Reusable Widget - Dashboard Hero Welcome Banner
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class WelcomeCard extends StatelessWidget {
  final String userName;
  final String customMessage;
  final String backgroundImage;

  const WelcomeCard({
    super.key,
    required this.userName,
    this.customMessage = "Stay connected with your child's learning and activities.",
    this.backgroundImage = 'assets/images/login-bg.png',
  });

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve current calendar date matching reference format
    final String dayName = DateFormat('EEEE').format(DateTime.now());
    final String fullDate = DateFormat('d MMMM yyyy').format(DateTime.now());
    final String formattedDate = "Today is $dayName, $fullDate";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Background image (school building)
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Horizontal linear opacity gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF021B3A).withOpacity(0.92),
                    const Color(0xFF021B3A).withOpacity(0.40),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 3. Profile details overlay text
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "Good Morning, ",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Text(
                      "👋",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                AppSpacing.h4,
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.h8,
                SizedBox(
                  width: 220,
                  child: Text(
                    customMessage,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.4,
                    ),
                  ),
                ),
                AppSpacing.h16,

                // 4. Dynamic date notification bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      AppSpacing.w8,
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
