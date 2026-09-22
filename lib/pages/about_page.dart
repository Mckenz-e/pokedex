import 'package:flutter/material.dart';

//* ข้อมูลผู้จัดทำ แก้ตรงนี้ที่เดียว
const String myName = '(Attapol Thinsophon)';

// เพิ่มข้อมูลได้อีก โดยใส่บรรทัดใหม่ เช่น 'Major': 'Computer Science',
const Map<String, String> myInfo = {
  'Student ID': '(6721602776)',
};

//* หน้าแสดงข้อมูลผู้จัดทำ (เปิดจากไอคอนมุมซ้ายบนของหน้า Home)
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Me')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.red,
              child: Icon(Icons.person, size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            myName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: myInfo.entries.map((entry) {
                return ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
