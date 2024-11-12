import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Approve user by setting `approved` to true
  Future<void> approveUser(String userId) async {
    await _firestore.collection('service_user').doc(userId).update({
      'approved': true,
    });
  }

  // Reject user by setting `approved` to false
  Future<void> rejectUser(String userId) async {
    await _firestore.collection('service_user').doc(userId).update({
      'approved': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('service_user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found"));
          }

          List<DocumentSnapshot> users = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items per row
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio:
                  0.75, // Adjust aspect ratio to make cards taller
            ),
            padding: EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> userData =
                  users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;
              bool isApproved = userData['approved'] ?? false;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User ID: $userId"),
                      SizedBox(height: 8),
                      Text("Name: ${userData['name'] ?? 'N/A'}"),
                      Text("City: ${userData['city'] ?? 'N/A'}"),
                      Text("Work: ${userData['work'] ?? 'N/A'}"),
                      SizedBox(height: 8),
                      if (userData.containsKey('document_verification'))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Documents:"),
                            for (String docType
                                in (userData['document_verification']
                                        as Map<String, dynamic>)
                                    .keys)
                              DocumentTile(
                                docType: docType,
                                frontImageUrl: userData['document_verification']
                                    [docType]['frontImageUrl'],
                                backImageUrl: userData['document_verification']
                                    [docType]['backImageUrl'],
                              ),
                          ],
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => approveUser(userId),
                            child: Text("Approve"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => rejectUser(userId),
                            child: Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            isApproved ? Icons.check_circle : Icons.cancel,
                            color: isApproved ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DocumentTile extends StatelessWidget {
  final String docType;
  final String? frontImageUrl;
  final String? backImageUrl;

  DocumentTile({required this.docType, this.frontImageUrl, this.backImageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          docType,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        if (frontImageUrl != null)
          Image.network(
            frontImageUrl!,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        if (backImageUrl != null)
          Image.network(
            backImageUrl!,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        SizedBox(height: 8),
      ],
    );
  }
}
