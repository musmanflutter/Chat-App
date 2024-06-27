import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messagecontroller = TextEditingController();

  @override
  void dispose() {
    _messagecontroller.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messagecontroller.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    //this ensures that keyboard is off once a message has been send
    FocusScope.of(context).unfocus();
    //here qe are fetching data of a current user
    //_message controller will be empty after sending data, so message sending  text field can be used again
    _messagecontroller.clear();
    final user = FirebaseAuth.instance.currentUser!;
    //here we are fecthing username,email and image of a user
    //get sends http get request to get data from there,
    final userData = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();
    //.add will add data directly, without creating a doc, where we need to provide an iq
    //the difference between doc and add aproach is there(doc) we set a document name while in add we dont set
    //it explicitly, instead it creates an automatically generated name
    //add automatically generates a unique id for us
    FirebaseFirestore.instance.collection('Chat').add({
      'text': enteredMessage,
      //Timestamp creates a time stamp
      'createAt': Timestamp.now(),
      'userId': user.uid,
      //.data contains all data of this user.
      //here we passed username key to get acces to data strored in that key
      'userName': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messagecontroller,
              //this will uppercase first letter of every sentence
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            onPressed: _submitMessage,
            icon: Icon(Icons.send),
          )
        ],
      ),
    );
  }
}
