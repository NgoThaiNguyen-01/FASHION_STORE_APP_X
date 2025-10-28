import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Liên hệ hỗ trợ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nếu bạn cần hỗ trợ hoặc có thắc mắc, vui lòng liên hệ qua:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // --- CARD ZALO ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                ),
                title: const Text('Zalo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('0849533344'),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.blueAccent),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- CARD EMAIL ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.pink.shade50,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: Icon(Icons.email_outlined, color: Colors.white),
                ),
                title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ngonguyen2004cm@gmail.com'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.pinkAccent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép email')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
