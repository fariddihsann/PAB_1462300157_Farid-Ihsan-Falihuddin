import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screens.dart';
import 'home_screens.dart'; // Import ini buat manggil DetailPage

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Data Realtime")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("Belum ada favorit."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(data['title']),
                onTap: () {
                  // Kirim data ke DetailPage agar bisa dilihat isinya
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(article: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: ListView(
        children: const [
          ListTile(
              leading: Icon(Icons.notifications_active),
              title: Text("Selamat datang di Space News!")),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DaftarPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Pengguna")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                    radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 20),
                Text(data?['nama'] ?? "Nama Tidak Diketahui",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(data?['email'] ?? user?.email ?? "Email Tidak Diketahui"),
                Text(data?['ig'] ?? "@instagram"),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _logout(context),
                  child: const Text("Log Out",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
