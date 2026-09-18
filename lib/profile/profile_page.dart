// ============================================================
// profile_page.dart — หน้าโปรไฟล์ผู้ใช้
// ============================================================
// ทำหน้าที่:
//   - แสดงข้อมูลโปรไฟล์ (ชื่อ, อีเมล, รูป)
//   - ถ้ายังไม่ login → แสดงปุ่ม "สมัครสมาชิก" (ไปหน้า Register โดยตรง)
//   - แสดงเมนู: ติวเตอร์, เครดิต, การจอง, ติดต่อ Admin, ออกจากระบบ
// ============================================================

import 'package:flutter/material.dart';
import 'profile_detail_page.dart';
import '../tutor/tutor_register_page.dart';
import '../tutor/tutor_manage_page.dart';
import '../widgets.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onRegister; // callback ไปหน้าสมัครสมาชิกโดยตรง
  final Future<void> Function()? onRefreshUser;

  const ProfilePage({
    super.key,
    this.userProfile,
    required this.onLogin,
    required this.onLogout,
    required this.onRegister,
    this.onRefreshUser,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _blue = Color(0xFF3c83f6);

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = widget.userProfile != null;
    final int tutStatus =
        int.tryParse(widget.userProfile?['tut_status']?.toString() ?? '-1') ??
        -1;
    final bool isApproved = tutStatus == 1;

    final String? imageUrl = isLoggedIn ? widget.userProfile!['mb_img'] : null;
    final String? fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? buildImageUrl(imageUrl)
        : null;
    final String fullName = isLoggedIn
        ? widget.userProfile!['mb_full_name']
        : 'Guest User';
    final String? email = isLoggedIn ? widget.userProfile!['mb_email'] : null;

    return Material(
      color: const Color(0xFFF5F7F8),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Card ──
            _buildHeader(
              isLoggedIn: isLoggedIn,
              fullName: fullName,
              email: email,
              fullImageUrl: fullImageUrl,
              isApproved: isApproved,
              tutStatus: tutStatus,
            ),

            const SizedBox(height: 16),

            // ── ปุ่มสมัครสมาชิก (แสดงเฉพาะตอนยังไม่ login) ──
            // กดแล้วไปหน้า RegisterPage โดยตรง ไม่ผ่าน LoginPage
            if (!isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onRegister,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

            // ── เมนู ──
            _buildMenuSection(isLoggedIn: isLoggedIn, isApproved: isApproved),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // Header Card — รูป + ชื่อ + badge สถานะ
  // ───────────────────────────────────────────
  Widget _buildHeader({
    required bool isLoggedIn,
    required String fullName,
    required String? email,
    required String? fullImageUrl,
    required bool isApproved,
    required int tutStatus,
  }) {
    return GestureDetector(
      onTap: () async {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนดูรายละเอียด')),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileDetailPage(
              userProfile: widget.userProfile!,
              onUserUpdated: (_) => widget.onRefreshUser?.call(),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            // รูปโปรไฟล์
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _blue.withValues(alpha: 0.1),
                  backgroundImage: fullImageUrl != null
                      ? NetworkImage(fullImageUrl)
                      : null,
                  child: fullImageUrl == null
                      ? const Icon(Icons.person, size: 38, color: _blue)
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 16),

            // ชื่อ + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            if (isLoggedIn)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // เมนูทั้งหมด — อยู่ใน Card เดียว
  // ───────────────────────────────────────────
  Widget _buildMenuSection({
    required bool isLoggedIn,
    required bool isApproved,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            icon: isApproved
                ? Icons.manage_accounts_rounded
                : Icons.assignment_ind_outlined,
            iconColor: _blue,
            title: isApproved ? 'จัดการข้อมูลติวเตอร์' : 'ลงทะเบียนติวเตอร์',
            subtitle: isApproved
                ? 'จัดการคอร์สและตารางสอน'
                : 'สมัครเป็นติวเตอร์',
            onTap: () async {
              if (!isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาเข้าสู่ระบบก่อนลงทะเบียนติวเตอร์'),
                  ),
                );
                return;
              }
              if (isApproved) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TutorManagePage(userProfile: widget.userProfile!),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TutorRegisterPage(userProfile: widget.userProfile!),
                  ),
                );
                await widget.onRefreshUser?.call();
              }
            },
            showDivider: true,
          ),
          if (isLoggedIn)
            _menuItem(
              icon: Icons.logout_rounded,
              iconColor: Colors.red,
              title: 'ออกจากระบบ',
              subtitle: '',
              onTap: widget.onLogout,
              showDivider: false,
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  // แต่ละแถวเมนู
  // ───────────────────────────────────────────
  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
    bool isDestructive = false,
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
                // icon กล่องสี่เหลี่ยม
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

                // title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDestructive
                              ? Colors.red
                              : const Color(0xFF101722),
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
