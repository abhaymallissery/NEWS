import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gxbgavoqareezszrsskc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4Ymdhdm9xYXJlZXpzenJzc2tjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5NDA0MTgsImV4cCI6MjA2NzUxNjQxOH0.6ZnuDmp9J0LdWz-DwNhXCCAGqkZwtrtGxpKaA21qohE',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase News Reader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NewsHomeScreen(),
    );
  }
}

// -------------------- Article Model --------------------
class Article {
  final int id;
  final String title;
  final String discription;
  final String url;
  final DateTime publishedAt;

  Article({
    required this.id,
    required this.title,
    required this.discription,
    required this.url,
    required this.publishedAt,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'],
      title: map['title'],
      discription: map['discription'],
      url: map['url'],
      publishedAt: DateTime.parse(map['published_at']),
    );
  }
}

// -------------------- Home Screen --------------------
class NewsHomeScreen extends StatefulWidget {
  @override
  _NewsHomeScreenState createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Article> _articles = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('news') // ✅ Replace with your actual table name
          .select()
          .order('published_at', ascending: false);

      final data = (response as List)
          .map((item) => Article.fromMap(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _articles = data
            .where((article) =>
                article.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      });
    } catch (e) {
      print('Fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch articles.')),
      );
    }

    setState(() => _loading = false);
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _fetchArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supabase News Reader'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search articles...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: _onSearch,
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchArticles,
                    child: ListView.builder(
                      itemCount: _articles.length,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return ListTile(
                          title: Text(article.title),
                          subtitle: Text(
                            article.discription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewsDetailScreen(article: article),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Detail Screen --------------------
class NewsDetailScreen extends StatelessWidget {
  final Article article;

  const NewsDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Published: ${article.publishedAt}"),
            SizedBox(height: 16),
            Text(article.discription),
            Spacer(),
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_browser),
              label: Text('Open Full Article'),
              onPressed: () => _launchURL(article.url, context),
            )
          ],
        ),
      ),
    );
  }

  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open URL: $url')),
      );
    }
  }
}
