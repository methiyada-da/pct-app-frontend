// profile_detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../appbar.dart';
import '../widgets.dart';
import 'change_pwd_page.dart';
import '../tutor/tutor_register_page.dart';
import '../tutor/tutor_manage_page.dart';
import '../config.dart';

class ProfileDetailPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Function(Map<String, dynamic>)? onUserUpdated;
  const ProfileDetailPage({
    super.key,
    required this.userProfile,
    this.onUserUpdated,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late String currentImg;
  late Map<String, dynamic> latestProfile;

  @override
  void initState() {
    super.initState();
    latestProfile = widget.userProfile;
    currentImg = widget.userProfile['mb_img'] ?? "";
    fetchLatestProfile();
  }

  Future<void> fetchLatestProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse("$kBaseUrl/get_user.php"),
            headers: apiHeaders(widget.userProfile),
          )
          .timeout(kApiTimeout);
      final res = jsonDecode(response.body);
      if (res['status'] == "success" && mounted) {
        if (!mounted) return;
        setState(() {
          latestProfile = attachToken(
            Map<String, dynamic>.from(res['userData']),
            widget.userProfile['_token'],
          );
          currentImg = latestProfile['mb_img'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("fetchLatestProfile error: $e");
    }
  }

  Future<void> updateImageAction() async {
    final imageData = await pickAndConvertImage();
    if (imageData != null) {
      try {
        final response = await http
            .post(
              Uri.parse("$kBaseUrl/update_member.php"),
              headers: apiHeaders(widget.userProfile),
              body: jsonEncode({"mb_img": imageData['base64']}),
            )
            .timeout(kApiTimeout);
        if (!mounted) return;
        final res = jsonDecode(response.body);
        if (res['status'] == "success") {
          final newImg = res['mb_img'] ?? "";
          setState(() => currentImg = newImg);
          if (widget.onUserUpdated != null) {
            final updatedUser = Map<String, dynamic>.from(widget.userProfile);
            updatedUser['mb_img'] = newImg;
            widget.onUserUpdated!(updatedUser);
          }
          showSnackBar(context, "อัปเดตรูปโปรไฟล์สำเร็จ", Colors.green);
        } else {
          showSnackBar(context, res['message'], Colors.red);
        }
      } catch (e) {
        debugPrint("updateImageAction error: $e");
        if (mounted) {
          showSnackBar(
            context,
            "อัปโหลดรูปล้มเหลว กรุณาลองใหม่อีกครั้ง",
            Colors.red,
          );
        }
      }
    }
  }

  // ── สถานะติวเตอร์ ──
  Widget _tutorStatusSection() {
    final tutStatus = latestProfile['tut_status'];
    if (tutStatus == null) {
      return _statusCard(
        icon: Icons.school_outlined,
        iconColor: Colors.grey,
        bgColor: Colors.grey.shade100,
        title: 'ยังไม่ได้สมัครเป็นติวเตอร์',
        subtitle: 'สมัครเพื่อเปิดคอร์สสอนและรับนักเรียนได้เลย',
        action: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TutorRegisterPage(userProfile: latestProfile),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('สมัครเป็นติวเตอร์'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3c83f6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    if (tutStatus.toString() == '0') {
      return _statusCard(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.orange,
        bgColor: Colors.orange.shade50,
        title: 'รอการอนุมัติ',
        subtitle: 'คำขอสมัครติวเตอร์ของคุณอยู่ระหว่างการพิจารณา',
        action: null,
      );
    }
    if (tutStatus.toString() == '1') {
      return _statusCard(
        icon: Icons.verified_rounded,
        iconColor: Colors.green,
        bgColor: Colors.green.shade50,
        title: 'ติวเตอร์ได้รับการอนุมัติแล้ว',
        subtitle: 'คุณสามารถเปิดคอร์สและรับนักเรียนได้แล้ว',
        action: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TutorManagePage(userProfile: latestProfile),
            ),
          ),
          icon: const Icon(Icons.manage_accounts_rounded, size: 18),
          label: const Text('จัดการข้อมูลติวเตอร์'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    if (tutStatus.toString() == '2') {
      return _statusCard(
        icon: Icons.cancel_outlined,
        iconColor: Colors.red,
        bgColor: Colors.red.shade50,
        title: 'ไม่ผ่านการอนุมัติ',
        subtitle: 'โปรดแก้ไขข้อมูลและส่งคำขอใหม่อีกครั้ง',
        action: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TutorRegisterPage(userProfile: latestProfile),
            ),
          ),
          icon: const Icon(Icons.edit_note, size: 18),
          label: const Text('แก้ไขและส่งใหม่'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _statusCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: iconColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (action != null) ...[const SizedBox(height: 12), action],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = buildImageUrl(currentImg);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'ข้อมูลส่วนตัว',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── รูปโปรไฟล์ ──
            GestureDetector(
              onTap: updateImageAction,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(
                        0xFF3c83f6,
                      ).withValues(alpha: 0.1),
                      backgroundImage: imgUrl.isNotEmpty
                          ? NetworkImage(imgUrl)
                          : null,
                      child: imgUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 52,
                              color: Color(0xFF3c83f6),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF3c83f6),
                        radius: 16,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              latestProfile['mb_full_name'] ?? '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              latestProfile['mb_email'] ?? '-',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // ── สถานะติวเตอร์ ──
            _tutorStatusSection(),

            const SizedBox(height: 16),

            // ── ข้อมูลส่วนตัว — รวมใน Card เดียว ──
            Container(
              width: double.infinity,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ข้อมูลส่วนตัว',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  labeledDisplay(
                    "คณะ",
                    latestProfile['fac_name'] ?? "-",
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 12),
                  labeledDisplay(
                    "สาขาวิชา",
                    latestProfile['mj_name'] ?? "-",
                    icon: Icons.book_outlined,
                  ),
                  const SizedBox(height: 12),
                  labeledDisplay(
                    "ชื่อ-นามสกุล",
                    latestProfile['mb_full_name'] ?? "-",
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  labeledDisplay(
                    "อีเมล",
                    latestProfile['mb_email'] ?? "-",
                    icon: Icons.email_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── เปลี่ยนรหัสผ่าน — Card แยก ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รหัสผ่าน',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.lock_outline,
                                color: Color(0xFF3c83f6),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '••••••••',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF101722),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChangePasswordPage(session: latestProfile),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text(
                          'เปลี่ยน',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3c83f6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
