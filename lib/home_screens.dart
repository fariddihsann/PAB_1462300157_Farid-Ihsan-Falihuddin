import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_service.dart';
import 'profile_screens.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const FavoritePage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Biar gak error kalau item > 3
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> newsFuture;

  @override
  void initState() {
    super.initState();
    newsFuture = ApiService.fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blueAccent,
            child: const Text("HEADLINE NEWS",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return const Center(child: Text("Error memuat berita"));

                final articles = snapshot.data!;
                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: article['image_url'] ?? '',
                        width: 100,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      title: Text(article['title'],
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(article['news_site'] ?? ''),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(article: article),
                            ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final dynamic article;
  const DetailPage({super.key, required this.article});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();

    if (widget.article['articleId'] != null) {
      setState(() => isFavorite = true);
    } else {
      _checkIfFavorite();
    }
  }

  void _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('articleId', isEqualTo: widget.article['id'].toString())
          .get();
      if (mounted) setState(() => isFavorite = doc.docs.isNotEmpty);
    }
  }

  void toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isFavorite) {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('articleId',
              isEqualTo: (widget.article['id'] ?? widget.article['articleId'])
                  .toString())
          .get();
      for (var d in doc.docs) {
        await d.reference.delete();
      }
      setState(() => isFavorite = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Dihapus dari Favorit")));
    } else {
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'articleId': widget.article['id'].toString(),
        'title': widget.article['title'],
        'image_url': widget.article['image_url'],
        'summary': widget.article['summary'],
        'news_site': widget.article['news_site'],
      });
      setState(() => isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ditambahkan ke Favorit!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Artikel"),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white),
            onPressed: toggleFavorite,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CachedNetworkImage(
                imageUrl: widget.article['image_url'] ?? '',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.article['title'],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Publisher: ${widget.article['news_site']}",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text(widget.article['summary'] ?? 'No summary',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
