import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts & Comments App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/posts-comments': (context) => CombinedListPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/posts-comments');
          },
          child: Text('View Posts & Comments'),
        ),
      ),
    );
  }
}

class CombinedListPage extends StatefulWidget {
  @override
  _CombinedListPageState createState() => _CombinedListPageState();
}

class _CombinedListPageState extends State<CombinedListPage> {
  late Future<Map<Post, List<Comment>>> _futurePostCommentMap;

  @override
  void initState() {
    super.initState();
    _futurePostCommentMap = fetchPostCommentMap();
  }

  Future<Map<Post, List<Comment>>> fetchPostCommentMap() async {
    try {
      final postResponse = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      final commentResponse = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/comments'));

      if (postResponse.statusCode == 200 && commentResponse.statusCode == 200) {
        final List<Post> posts = (json.decode(postResponse.body) as List)
            .take(10)
            .map((json) => Post.fromJson(json))
            .toList();

        final List<Comment> comments = (json.decode(commentResponse.body) as List)
            .map((json) => Comment.fromJson(json))
            .toList();

        final Map<Post, List<Comment>> postCommentMap = {};

        for (final post in posts) {
          postCommentMap[post] = comments.where((comment) => comment.postId == post.id).toList();
        }

        return postCommentMap;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts & Comments'),
      ),
      body: FutureBuilder<Map<Post, List<Comment>>>(
        future: _futurePostCommentMap,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final postCommentMap = snapshot.data!;
            return ListView.separated(
              padding: EdgeInsets.all(8.0),
              itemCount: postCommentMap.entries.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final entry = postCommentMap.entries.elementAt(index);
                final post = entry.key;
                final comments = entry.value;

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    leading: Icon(Icons.article, color: Colors.blue),
                    title: Text(
                      post.title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(post.body),
                    children: comments.map((comment) {
                      return ListTile(
                        leading: Icon(Icons.comment, color: Colors.green),
                        title: Text(comment.name),
                        subtitle: Text(comment.body),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.home),
        tooltip: 'Back to Home',
      ),
    );
  }
}

class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

class Comment {
  final int postId;
  final String name;
  final String body;

  Comment({required this.postId, required this.name, required this.body});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: json['postId'],
      name: json['name'],
      body: json['body'],
    );
  }
}
