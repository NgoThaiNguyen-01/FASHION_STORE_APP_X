import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class ManHinhChao extends StatefulWidget {
  const ManHinhChao({super.key});

  @override
  State<ManHinhChao> createState() => _ManHinhChaoState();
}

class _ManHinhChaoState extends State<ManHinhChao>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _hieuUngMoDan;

  @override
  void initState() {
    super.initState();

    // 🎬 Hiệu ứng mờ dần cho logo T&N
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _hieuUngMoDan = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    // ⏱️ Chuyển sang màn hình chính sau 3.5 giây
    Timer(const Duration(seconds: 15, milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chieuRong = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌆 Ảnh nền thời trang
          Image.asset(
            'assets/images/tn_hero.jpg',
            fit: BoxFit.cover,
          ),

          // 🌫️ Lớp phủ làm mờ ảnh nền
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                ],
              ),
            ),
          ),

          // ✨ Logo "T&N" kiểu viết tay như H&M
          FadeTransition(
            opacity: _hieuUngMoDan,
            child: Center(
              child: Transform.rotate(
                angle: -0.07, // nghiêng nhẹ
                child: Text(
                  'T&N',
                  style: GoogleFonts.satisfy(
                    color: const Color(0xFFE10000),
                    fontSize: chieuRong * 0.3,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -4,
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🕓 Dòng chữ giới thiệu nhỏ bên dưới logo
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: FadeTransition(
                opacity: _hieuUngMoDan,
                child: Text(
                  "Thời trang phong cách hiện đại",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
