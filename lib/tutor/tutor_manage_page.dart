// tutor_manage_page.dart
import 'package:flutter/material.dart';
import '../appbar.dart';
import 'course_list_page.dart';
import 'tutor_course_page.dart';
import '../widgets.dart';

class TutorManagePage extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const TutorManagePage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'จัดการข้อมูลติวเตอร์',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── เมนู ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _menuItem(
                    context,
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF3c83f6),
                    title: 'คอร์สเรียน',
                    subtitle: 'ดูและจัดการคอร์สที่เปิดสอน',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourseListPage(userProfile: userProfile),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _menuItem(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: Colors.green,
                    title: 'เพิ่มคอร์สเรียน',
                    subtitle: 'สร้างคอร์สสอนใหม่',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TutorCoursePage(userProfile: userProfile),
                      ),
                    ),
                    showDivider: true,
                  ),
                  _menuItem(
                    context,
                    icon: Icons.pending_actions_rounded,
                    iconColor: Colors.orange,
                    title: 'คำขอจองเรียน',
                    subtitle: 'ตรวจสอบและยืนยันคำขอจากนักเรียน',
                    onTap: () => showComingSoon(context),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF101722),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}
