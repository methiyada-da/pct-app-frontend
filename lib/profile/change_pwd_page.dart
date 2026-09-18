// change_pwd_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets.dart';
import '../appbar.dart';
import '../config.dart';

class ChangePasswordPage extends StatefulWidget {
  final Map<String, dynamic> session;
  const ChangePasswordPage({super.key, required this.session});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPass = TextEditingController();
  final TextEditingController newPass = TextEditingController();
  final TextEditingController confirmPass = TextEditingController();
  bool isOldVisible = false;
  bool isNewVisible = false;
  bool isConfirmVisible = false;

  @override
  void dispose() {
    oldPass.dispose();
    newPass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  Future<void> updatePasswordAction() async {
    if (oldPass.text.isEmpty ||
        newPass.text.isEmpty ||
        confirmPass.text.isEmpty) {
      showSnackBar(context, "กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }
    if (newPass.text != confirmPass.text) {
      showSnackBar(context, "รหัสผ่านใหม่ไม่ตรงกัน", Colors.red);
      return;
    }
    if (newPass.text.length < 8) {
      showSnackBar(
        context,
        "รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร",
        Colors.orange,
      );
      return;
    }
    if (oldPass.text == newPass.text) {
      showSnackBar(
        context,
        "รหัสผ่านใหม่ต้องไม่เหมือนรหัสผ่านเดิม",
        Colors.orange,
      );
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/update_member.php"),
            headers: apiHeaders(widget.session),
            body: jsonEncode({
              "old_pwd": oldPass.text,
              "mb_pwd": newPass.text,
              "cf_pwd": confirmPass.text,
            }),
          )
          .timeout(kApiTimeout);
      if (!mounted) return;
      final res = jsonDecode(response.body);
      if (res['status'] == "success") {
        showSnackBar(context, "เปลี่ยนรหัสผ่านสำเร็จ", Colors.green);
        Navigator.pop(context);
      } else {
        showSnackBar(context, res['message'], Colors.red);
      }
    } catch (e) {
      debugPrint("Error updating password: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: "เปลี่ยนรหัสผ่าน",
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Header Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3c83f6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3c83f6).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3c83f6).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF3c83f6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เปลี่ยนรหัสผ่าน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF3c83f6),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'กรอกรหัสผ่านเดิมและตั้งรหัสใหม่ที่ต้องการ',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── ฟอร์ม ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  inputPassword(
                    oldPass,
                    "กรอกรหัสผ่านเดิม",
                    isOldVisible,
                    () => setState(() => isOldVisible = !isOldVisible),
                    label: "รหัสผ่านเดิม",
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 20),
                  inputPassword(
                    newPass,
                    "กรอกรหัสผ่านใหม่",
                    isNewVisible,
                    () => setState(() => isNewVisible = !isNewVisible),
                    label: "รหัสผ่านใหม่",
                  ),
                  const SizedBox(height: 20),
                  inputPassword(
                    confirmPass,
                    "ยืนยันรหัสผ่านใหม่",
                    isConfirmVisible,
                    () => setState(() => isConfirmVisible = !isConfirmVisible),
                    label: "ยืนยันรหัสผ่านใหม่",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: buttonAction(
                "บันทึกการเปลี่ยนรหัส",
                updatePasswordAction,
                icon: Icons.save_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
