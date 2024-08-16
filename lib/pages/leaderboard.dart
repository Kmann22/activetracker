import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
        backgroundColor:
            Colors.deepPurple, // Change the color to your preference
      ),
      body: Container(
        color: Colors.grey[200], // Background color for the screen
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('totalSteps', descending: true)
              .limit(10) // Limit to top 10 users
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text('No data available',
                      style: TextStyle(fontSize: 18)));
            }

            // Retrieve and map the user data
            final users = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final userName = userDoc['userName'] ?? 'Anonymous';
                final totalSteps = userDoc['totalSteps'] ?? 0;
                final rank = index + 1;

                // Create ranking badge
                String rankBadge;
                if (rank == 1) {
                  rankBadge = '🥇';
                } else if (rank == 2) {
                  rankBadge = '🥈';
                } else if (rank == 3) {
                  rankBadge = '🥉';
                } else {
                  rankBadge = '$rank';
                }

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(rankBadge,
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    title: Text(userName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Steps: $totalSteps',
                        style: TextStyle(color: Colors.grey[700])),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
