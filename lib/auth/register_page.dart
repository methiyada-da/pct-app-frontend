// ============================================================
// register_page.dart — หน้าสมัครสมาชิก
// ============================================================
// ทำหน้าที่:
//   - โหลดรายการคณะและสาขาจาก API เพื่อให้ผู้ใช้เลือก
//   - รับข้อมูลส่วนตัว: ชื่อ, นามสกุล, อีเมล, รหัสผ่าน
//   - ส่งข้อมูลไปยัง API (create_member.php) เพื่อสร้างบัญชี
//   - เมื่อสำเร็จ นำผู้ใช้ไปหน้า MainNavigation ทันที (ไม่ต้อง login ซ้ำ)
// ============================================================

import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets.dart';
import '../appbar.dart';
import '../main_navigation.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── STEP 1: ประกาศตัวแปรควบคุม UI ──────────────────────────
  // Controller แต่ละตัวผูกกับช่องกรอกข้อมูลของตัวเอง
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  // faculties = ทั้งหมดจาก API
  // allMajors = สาขาทั้งหมด, filteredMajors = กรองตามคณะที่เลือก
  List faculties = [], allMajors = [], filteredMajors = [];
  String? selectedFacId, selectedMjId;
  bool isLoading = false;

  // แยก isVisible สำหรับช่องรหัสผ่านแต่ละช่อง
  bool isPassVisible = false;
  bool isConfirmPassVisible = false;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลคณะ/สาขาทันทีที่หน้าเปิด
    // เพื่อให้ Dropdown พร้อมใช้งานก่อนที่ผู้ใช้จะกรอกข้อมูล
    fetchOptions();
  }

  @override
  void dispose() {
    // คืน memory ของ controller ทุกตัวเมื่อหน้าถูกทำลาย
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── STEP 2: โหลดตัวเลือกคณะและสาขา (fetchOptions) ──────────
  // ดึงข้อมูลจาก API ครั้งเดียว แล้วเก็บใน state
  // การกรองสาขาตามคณะทำฝั่ง client เพื่อลด request ที่ไม่จำเป็น
  Future<void> fetchOptions() async {
    try {
      final response = await http
          .get(Uri.parse("$kBaseUrl/get_options.php"))
          .timeout(kApiTimeout);
      if (!mounted) return;
      final data = json.decode(response.body);
      if (data['status'] == "success") {
        setState(() {
          faculties = data['faculties'];
          allMajors = data['majors'];
        });
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "โหลดข้อมูลล้มเหลว", Colors.red);
    }
  }

  // ── STEP 3: ฟังก์ชันสมัครสมาชิก (registerAction) ────────────
  Future<void> registerAction() async {
    // [3.1] ตรวจสอบว่ากรอกทุกช่องและเลือกสาขาแล้ว
    //       ใช้ .any() เพื่อเช็คทุก controller ในครั้งเดียว
    if ([
          firstNameCtrl,
          lastNameCtrl,
          emailCtrl,
          passCtrl,
          confirmPassCtrl,
        ].any((c) => c.text.isEmpty) ||
        selectedMjId == null) {
      showSnackBar(context, "กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    // [3.2] ตรวจสอบรหัสผ่านสองช่องตรงกันก่อนส่ง API
    //       ป้องกันการสมัครด้วยรหัสผ่านที่พิมพ์ผิด
    if (passCtrl.text != confirmPassCtrl.text) {
      showSnackBar(context, "รหัสผ่านไม่ตรงกัน", Colors.red);
      return;
    }
    if (passCtrl.text.length < 8) {
      showSnackBar(
        context,
        "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร",
        Colors.orange,
      );
      return;
    }

    // [3.3] เปิด Loading state เพื่อบล็อกการกดปุ่มซ้ำ
    setState(() => isLoading = true);

    try {
      // [3.4] รวมชื่อ-นามสกุลเป็น fullName ก่อนส่ง
      //       เพราะ API รับเป็น field เดียว (mb_full_name)
      final fullName =
          "${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}";

      final response = await http
          .post(
            Uri.parse("$kBaseUrl/create_member.php"),
            headers: apiHeaders(),
            body: jsonEncode({
              "mb_full_name": fullName,
              "mb_email": emailCtrl.text,
              "mb_pwd": passCtrl.text,
              "cf_pwd": confirmPassCtrl.text,
              "mj_id": selectedMjId!,
            }),
          )
          .timeout(kApiTimeout);

      if (!mounted) return;
      final respJson = json.decode(response.body);

      if (respJson['status'] == "success") {
        showSnackBar(context, "สมัครสมาชิกสำเร็จ!", Colors.green);

        // [3.5] API ส่ง userData ครบมาพร้อม (JOIN คณะ/สาขา/tut_status แล้ว)
        //       จึงไม่ต้อง call get_user.php ซ้ำอีกรอบ ประหยัด 1 request
        final Map<String, dynamic> fullUserData = attachToken(
          Map<String, dynamic>.from(respJson['userData']),
          respJson['token'],
        );

        // [3.6] ลบ stack ทั้งหมดแล้วไป MainNavigation
        //       ใช้ pushAndRemoveUntil เพื่อไม่ให้กด back กลับมาหน้า Register ได้
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(initialUser: fullUserData),
          ),
          (route) => false,
        );
      } else {
        showSnackBar(context, respJson['message'], Colors.red);
      }
    } catch (e) {
      // [3.7] จับ error กรณีเน็ตหลุด หรือ server ไม่ตอบสนอง
      if (mounted) showSnackBar(context, "การเชื่อมต่อขัดข้อง", Colors.red);
    } finally {
      // [3.8] ปิด Loading ทุกกรณี และตรวจ mounted ก่อนเสมอ
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── STEP 4: สร้าง UI ของหน้า Register ───────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'สมัครสมาชิก',
        onPrimaryAction: () => Navigator.pop(context),
        isLoginPage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // ── โลโก้และหัวข้อ ──
            appLogo(),
            const SizedBox(height: 16),
            const Text(
              'สร้างบัญชีใหม่',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 32),

            // ── เลือกคณะ ──
            // เมื่อเลือกคณะ จะ filter สาขาให้แสดงเฉพาะสาขาในคณะนั้น
            // และ reset selectedMjId เพื่อป้องกันสาขาเก่าค้างอยู่
            inputDropdown(
              label: 'คณะ',
              hint: 'เลือกคณะของคุณ',
              icon: Icons.account_balance,
              value: selectedFacId,
              items: faculties,
              itemKey: 'fac_id',
              itemLabel: 'fac_name',
              onChanged: (val) => setState(() {
                selectedFacId = val;
                selectedMjId = null;
                filteredMajors = allMajors
                    .where((mj) => mj['fac_id'].toString() == val)
                    .toList();
              }),
            ),
            const SizedBox(height: 20),

            // ── เลือกสาขา (แสดงเฉพาะสาขาของคณะที่เลือก) ──
            inputDropdown(
              label: 'สาขาวิชา',
              hint: 'เลือกสาขาวิชาของคุณ',
              icon: Icons.book,
              value: selectedMjId,
              items: filteredMajors,
              itemKey: 'mj_id',
              itemLabel: 'mj_name',
              onChanged: (val) => setState(() => selectedMjId = val),
            ),
            const SizedBox(height: 20),

            // ── ชื่อและนามสกุล ──
            inputText(
              firstNameCtrl,
              label: 'ชื่อ',
              'กรุณากรอกชื่อภาษาไทย',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            inputText(
              lastNameCtrl,
              label: 'นามสกุล',
              'กรุณากรอกนามสกุลภาษาไทย',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // ── อีเมล ──
            inputText(
              emailCtrl,
              label: 'อีเมล',
              'กรุณากรอกอีเมล',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),

            // ── รหัสผ่านและยืนยันรหัสผ่าน (มีปุ่มแสดง/ซ่อนแยกกัน) ──
            inputPassword(
              passCtrl,
              'กรุณากรอกรหัสผ่าน',
              isPassVisible,
              () => setState(() => isPassVisible = !isPassVisible),
              label: 'รหัสผ่าน',
            ),
            const SizedBox(height: 20),
            inputPassword(
              confirmPassCtrl,
              'กรุณายืนยันรหัสผ่าน',
              isConfirmPassVisible,
              () =>
                  setState(() => isConfirmPassVisible = !isConfirmPassVisible),
              label: 'ยืนยันรหัสผ่าน',
            ),
            const SizedBox(height: 32),

            // ── ปุ่มสมัครสมาชิก / Loading indicator ──
            // สลับแสดงตาม isLoading เพื่อป้องกันกดซ้ำ
            SizedBox(
              width: double.infinity,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buttonAction('สมัครสมาชิก', registerAction),
            ),
          ],
        ),
      ),
    );
  }
}
