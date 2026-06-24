import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget {
  final bool isMobile;

  const TopNavbar({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          // ☰ MOBILE MENU (Shows only on mobile screens)
          if (isMobile) ...[
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 🖼️ LOGO
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              height: 35,
              width: 35,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if logo.png is missing during development
                return const Icon(Icons.apartment, color: Colors.white);
              },
            ),
          ),

          const SizedBox(width: 12),

          // 🔒 EXPANDED TEXT (Safely absorbs available room and pushes actions right)
          const Expanded(
            child: Text(
              "Rent Management",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          const SizedBox(width: 16),

          // 🔔 ACTIONS AREA
          const Icon(Icons.notifications, color: Colors.white),

          const SizedBox(width: 16),

          const CircleAvatar(
            backgroundColor: Color(0xFF334155),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}