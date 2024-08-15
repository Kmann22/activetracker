import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalSteps', descending: true)
            .limit(10) // Limit to top 10 users, you can adjust this number
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          }

          // Retrieve and map the user data
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userName = userDoc['displayName'] ?? 'Anonymous';
              final totalSteps = userDoc['totalSteps'] ?? 0;

              return ListTile(
                leading: CircleAvatar(child: Text('#${index + 1}')),
                title: Text(userName),
                subtitle: Text('Steps: $totalSteps'),
              );
            },
          );
        },
      ),
    );
  }
}
