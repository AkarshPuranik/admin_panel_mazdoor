import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('service_user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final phoneNumber = userDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('service_user')
                    .doc(phoneNumber)
                    .collection('document_verification')
                    .snapshots(),
                builder: (context, docSnapshot) {
                  if (docSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!docSnapshot.hasData || docSnapshot.data!.docs.isEmpty) {
                    return SizedBox(); // Skip users with no documents
                  }

                  return ExpansionTile(
                    title: Text('Phone: $phoneNumber'),
                    children: docSnapshot.data!.docs.map((doc) {
                      final documentType = doc.id;
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';

                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(documentType),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data['frontImageUrl'] != null)
                                GestureDetector(
                                  onTap: () {
                                    _showImageDialog(context, data['frontImageUrl']);
                                  },
                                  child: Image.network(
                                    data['frontImageUrl'],
                                    height: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text('Error loading front image',
                                          style: TextStyle(color: Colors.red));
                                    },
                                  ),
                                ),
                              if (data['backImageUrl'] != null)
                                GestureDetector(
                                  onTap: () {
                                    _showImageDialog(context, data['backImageUrl']);
                                  },
                                  child: Image.network(
                                    data['backImageUrl'],
                                    height: 150,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text('Error loading back image',
                                          style: TextStyle(color: Colors.red));
                                    },
                                  ),
                                ),
                              Text('Status: ${status.toUpperCase()}'),
                              Row(
                                children: [
                                  Text("Approve"),
                                  Switch(
                                    value: status == "approved",
                                    onChanged: (value) {
                                      _updateStatus(
                                          phoneNumber, documentType, value);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(String phoneNumber, String documentType, bool isApproved) async {
    final status = isApproved ? "approved" : "rejected";

    try {
      await firestore
          .collection('service_user')
          .doc(phoneNumber)
          .collection('document_verification')
          .doc(documentType)
          .update({'status': status});
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) {
                  return Text('Error loading image');
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }
}
