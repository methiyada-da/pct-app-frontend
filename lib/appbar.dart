// appbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';

PreferredSizeWidget myAppBar({
  required String titleText,
  required VoidCallback onPrimaryAction,
  VoidCallback? onLoginPressed,
  VoidCallback? onProfilePressed,
  String? userImage,
  bool isLoginPage = false,
}) {
  final String? imageUrl = userImage != null ? buildImageUrl(userImage) : null;

  return AppBar(
    backgroundColor: const Color(0xFF3c83f6),
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 8,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Color(
        0xFF3c83f6,
      ), // พื้นหลัง status bar = สีฟ้าเดียวกับ AppBar
      statusBarIconBrightness: Brightness.light, // icon เวลา/สัญญาณ = สีขาว
    ),

    leading: isLoginPage
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onPrimaryAction,
          )
        : Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF3c83f6),
                  size: 18,
                ),
              ),
            ),
          ),

    title: Text(
      titleText,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.white,
      ),
    ),

    centerTitle: isLoginPage,

    actions: [
      if (!isLoginPage) ...[
        if (userImage != null)
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: onProfilePressed,
              child: Center(
                child: CircleAvatar(
                  radius: 18,
                  // แก้ (2026-03-10): พื้นหลัง avatar เป็นขาวโปร่งแสง ให้เข้ากับ AppBar สีฟ้า
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3c83f6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log In',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
      ],
    ],
  );
}
