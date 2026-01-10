import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_research_2026/VideoChatScreen.dart';

import 'Chat.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat List"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get all users except the current logged-in user
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUser!.uid).toList();

          if (users.isEmpty) {
            return const Center(child: Text("No other users available."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user['name']),
                subtitle: Text(user['email']),
                onTap: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context) => Chat(peerId: user['userid'],peerName: user['name'])));
                  //Navigator.push(context,MaterialPageRoute(builder: (context) => VideoChatScreen()));
                },
              );
            },
          );
        },
      ),
    );
  }
}
