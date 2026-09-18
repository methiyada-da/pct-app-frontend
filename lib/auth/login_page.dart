// ============================================================
// login_page.dart — หน้าเข้าสู่ระบบ
// ============================================================
// ทำหน้าที่:
//   - รับอีเมลและรหัสผ่านจากผู้ใช้
//   - ส่งข้อมูลไปยัง API (login.php) เพื่อตรวจสอบสิทธิ์
//   - เมื่อสำเร็จ ส่ง userData กลับไปให้หน้าที่เรียกใช้
//   - มีลิ้งค์ไปหน้าสมัครสมาชิก (RegisterPage)
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets.dart';
import '../appbar.dart';
import 'register_page.dart';
import '../config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── STEP 1: ประกาศตัวแปรควบคุม UI ──────────────────────────
  // TextEditingController ใช้ดึงค่าจากช่องกรอกข้อมูล
  // _isPasswordVisible ควบคุมการแสดง/ซ่อนรหัสผ่าน
  // isLoading ใช้สลับระหว่างปุ่มกด กับ Loading indicator
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    // คืน memory คืนเมื่อหน้านี้ถูกทำลาย ป้องกัน memory leak
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // ── STEP 2: ฟังก์ชันเข้าสู่ระบบ (loginAction) ──────────────
  Future<void> loginAction() async {
    // [2.1] ตรวจสอบว่ากรอกข้อมูลครบก่อน ถึงจะยิง API
    //       ป้องกัน request ที่ไม่จำเป็นและแจ้งผู้ใช้ทันที
    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      showSnackBar(context, "กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    // [2.2] เปิด Loading state เพื่อบล็อกปุ่มกดซ้ำระหว่างรอ API
    setState(() => isLoading = true);

    try {
      // [2.3] ส่ง POST request ไปยัง login.php พร้อม email และ password
      //       ใช้ jsonEncode เพราะ API รับเป็น JSON format
      final response = await http
          .post(
            Uri.parse("$kBaseUrl/login.php"),
            headers: apiHeaders(),
            body: jsonEncode({
              "email": userCtrl.text,
              "password": passCtrl.text,
            }),
          )
          .timeout(kApiTimeout);

      if (!mounted) return;
      final res = jsonDecode(response.body);

      // [2.4] ตรวจ status จาก API
      //       ถ้าสำเร็จ → ส่ง userData กลับไปให้หน้าแม่ผ่าน Navigator.pop
      //       ถ้าล้มเหลว → แสดง error message จาก server
      if (res['status'] == "success") {
        showSnackBar(context, "เข้าสู่ระบบสำเร็จ", Colors.green);
        final user = attachToken(
          Map<String, dynamic>.from(res['userData']),
          res['token'],
        );
        Navigator.pop(context, user);
      } else {
        showSnackBar(
          context,
          res['message'] ?? "เข้าสู่ระบบล้มเหลว",
          Colors.red,
        );
      }
    } catch (e) {
      // [2.5] จับ error กรณีเน็ตหลุด หรือ server ไม่ตอบสนอง
      if (mounted) {
        showSnackBar(context, "การเชื่อมต่อขัดข้อง: $e", Colors.red);
      }
    } finally {
      // [2.6] ปิด Loading ทุกกรณี ไม่ว่าจะสำเร็จหรือล้มเหลว
      //       ตรวจ mounted ก่อน เพราะ widget อาจถูก dispose ไปแล้ว
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── STEP 3: สร้าง UI ของหน้า Login ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'เข้าสู่ระบบ',
        onPrimaryAction: () => Navigator.of(context).popUntil((r) => r.isFirst),
        isLoginPage: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── โลโก้และข้อความต้อนรับ ──
              appLogo(),
              const SizedBox(height: 16),
              const Text(
                'ยินดีต้อนรับ',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const Text(
                'เข้าสู่ระบบเพื่อเริ่มต้นการเรียนรู้',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── ช่องกรอกอีเมล ──
              inputText(
                userCtrl,
                'กรุณากรอกอีเมล',
                label: 'อีเมล',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // ── ช่องกรอกรหัสผ่าน (มีปุ่มแสดง/ซ่อน) ──
              inputPassword(
                passCtrl,
                'กรุณากรอกรหัสผ่าน',
                _isPasswordVisible,
                () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                label: 'รหัสผ่าน',
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 24),

              // ── ปุ่มเข้าสู่ระบบ / Loading indicator ──
              // สลับแสดงตาม isLoading เพื่อป้องกันกดซ้ำ
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : buttonAction('เข้าสู่ระบบ', loginAction),
              ),
              const SizedBox(height: 32),

              // ── ลิ้งค์ไปหน้าสมัครสมาชิก ──
              // ถ้าสมัครสำเร็จจาก RegisterPage จะได้ userData กลับมา
              // แล้ว pop ต่อทันที ไม่ต้อง login ซ้ำ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ยังไม่มีบัญชี? '),
                  GestureDetector(
                    onTap: () async {
                      final newUser = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                      if (newUser != null && newUser is Map<String, dynamic>) {
                        if (!context.mounted) return;
                        Navigator.pop(context, newUser);
                      }
                    },
                    child: const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(
                        color: Color(0xFF3c83f6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
