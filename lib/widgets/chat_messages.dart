import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUSer = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      //this stream will listen to changes and run builder fucntion based on that stream
      //we are able to listen to chnages by accessing snapshots in our chat folder in DB
      //orderBy defines order in which data should be displayed
      //it takes a key rhat should be available in db(we gave createAt) and the order
      //so we said the latest message should be in bottom
      stream: FirebaseFirestore.instance
          .collection('Chat')
          .orderBy(
            'createAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        //!chatSnapshot.hasData this checks if we dont have data
        //chatSnapshot.data!.docs.isEmpty this checks if we have data but its (docs) an empty list
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No Messages Found'),
          );
        }
        if (chatSnapshot.hasError) {
          return Center(
            child: Text('Something went Wrong'),
          );
        }
        final loadedMessages = chatSnapshot.data!.docs;
        //if we passed both above checks, that means we have data, so we showed a list view
        return ListView.builder(
          padding: EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          //this makes sure that the list of messages start from bottom
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            //here we are chicking if its a message of same user(message send) or by different user(message got)
            //we are checking if index+1<loadedmessages.length that means we do have a different message
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;
            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: authenticatedUSer.uid == currentMessageUserId,
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['userName'],
                message: chatMessage['text'],
                isMe: authenticatedUSer.uid == currentMessageUserId,
              );
            }
          },
        );
      },
    );
  }
}
