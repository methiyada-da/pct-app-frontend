// ============================================================
// main_navigation.dart — จุดกลางของแอป (Shell หลัก)
// ============================================================
// ทำหน้าที่:
//   - ควบคุม Bottom Navigation Bar (4 แท็บ)
//   - เก็บ state ของ currentUser และแชร์ให้ทุกหน้า
//   - จัดการ login / register / logout / refresh user
//   - AppBar ปุ่ม "Log In" → ไปหน้า LoginPage (ซึ่งมีลิ้งค์ไป Register ได้เอง)
//   - ปุ่ม "สมัครสมาชิก" ใน ProfilePage → ไปหน้า RegisterPage โดยตรง
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'appbar.dart';
import 'bottom_nav.dart';
import 'widgets.dart';
import 'config.dart';

import 'search/home_page.dart';
import 'search/search_page.dart';
import 'chat/chat_page.dart';
import 'profile/profile_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic>? initialUser;

  const MainNavigation({super.key, this.initialUser});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // ── STEP 1: ตัวแปร state หลักของแอป ────────────────────────
  // _selectedIndex = แท็บที่เลือกอยู่ใน BottomNav
  // currentUser = ข้อมูลผู้ใช้ที่ login อยู่ (null = ยังไม่ login)
  // _searchKeyword = คำค้นหาที่ส่งจาก HomePage ไปยัง SearchPage
  int _selectedIndex = 0;
  Map<String, dynamic>? currentUser;
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    currentUser = widget.initialUser;
  }

  // ── STEP 2: จัดการ Navigation ───────────────────────────────

  // [2.1] เปลี่ยนแท็บ และล้าง keyword ถ้าออกจากหน้าค้นหา
  void _onNavItemTapped(int index) {
    setState(() {
      if (_selectedIndex == 1 && index != 1) {
        _searchKeyword = "";
      }
      _selectedIndex = index;
    });
  }

  // [2.2] รับ keyword จาก HomePage แล้วกระโดดไปหน้าค้นหาทันที
  void _handleSearch(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _selectedIndex = 1;
    });
  }

  // ── STEP 3: จัดการข้อมูลผู้ใช้ ─────────────────────────────

  // [3.1] โหลดข้อมูล user ใหม่จาก API
  //       ใช้หลังจาก login หรือหลังแก้ข้อมูลโปรไฟล์
  Future<void> refreshUser() async {
    if (currentUser == null) return;
    try {
      final response = await http
          .get(
            Uri.parse("$kBaseUrl/get_user.php"),
            headers: apiHeaders(currentUser),
          )
          .timeout(kApiTimeout);
      final res = jsonDecode(response.body);
      if (res['status'] == "success") {
        final token = currentUser!['_token'];
        final refreshed = attachToken(
          Map<String, dynamic>.from(res['userData']),
          token,
        );
        if (!mounted) return;
        setState(() => currentUser = refreshed);
      }
    } catch (e) {
      debugPrint("refreshUser error: $e");
    }
  }

  // [3.2] เปิดหน้า Login
  //       ใช้โดย: ปุ่ม "Log In" บน AppBar
  //       หน้า LoginPage มีลิ้งค์ไปสมัครสมาชิกได้เองอยู่แล้ว
  Future<void> openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => currentUser = result);
      await refreshUser();
    }
  }

  // [3.3] เปิดหน้า Register โดยตรง
  //       ใช้โดย: ปุ่ม "สมัครสมาชิก" ใน ProfilePage
  //       ข้ามหน้า Login ไปเลย เพื่อ UX ที่รวดเร็วกว่า
  Future<void> openRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
    if (!mounted) return;
    // RegisterPage จะ pushAndRemoveUntil ไปเอง ถ้าสมัครสำเร็จ
    // แต่ถ้า user กด back กลับมา ให้เช็คว่ามี result ส่งมาหรือเปล่า
    if (result != null && result is Map<String, dynamic>) {
      setState(() => currentUser = result);
      await refreshUser();
    }
  }

  // [3.4] ล้างข้อมูล user และกลับหน้าแรก
  void logout() {
    setState(() {
      currentUser = null;
      _selectedIndex = 0;
    });
  }

  // ── STEP 4: เลือกหน้าตาม index ที่กด ───────────────────────
  Widget getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          userData: currentUser,
          onSearch: _handleSearch,
          onUserUpdated: (user) => setState(() => currentUser = user),
        );
      case 1:
        return SearchPage(
          key: ValueKey(_searchKeyword),
          userProfile: currentUser,
          initialKeyword: _searchKeyword,
          onUserUpdated: (user) => setState(() => currentUser = user),
        );
      case 2:
        return ChatPage(
          key: ValueKey(currentUser?['mb_id']),
          userProfile: currentUser,
          onLogin: openLogin,
        );
      case 3:
        return ProfilePage(
          userProfile: currentUser,
          onLogout: logout,
          onLogin: openLogin,
          onRegister:
              openRegister, // ปุ่มสมัครสมาชิกใน ProfilePage → openRegister
          onRefreshUser: refreshUser,
        );
      default:
        throw UnimplementedError('No page for index $_selectedIndex');
    }
  }

  // ── STEP 5: สร้าง UI หลัก ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: myAppBar(
        titleText: 'Puean Chuay Tu',
        onPrimaryAction: () => showComingSoon(context),
        userImage: currentUser != null ? currentUser!['mb_img'] : null,
        // ปุ่ม "Log In" บน AppBar → ไปหน้า LoginPage
        // (LoginPage มีลิ้งค์ไปสมัครสมาชิกอยู่แล้ว)
        onLoginPressed: openLogin,
        onProfilePressed: () => setState(() => _selectedIndex = 3),
      ),
      body: getCurrentPage(),
      bottomNavigationBar: MyBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}
