import 'package:chat_app/screens/chat.dart';
import 'package:chat_app/screens/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:chat_app/screens/auth.dart';

void main() async {
  //this ensures we dont get stuck on starting screen while using firebase
  WidgetsFlutterBinding.ensureInitialized();
  //all this await is told to do by firebase official docs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      //StreamBuilder is like futurebuilder
      //builder will automatically called by flutter based on stream we provide
      //authStateChanges Notifies about changes to the user's sign-in state (such as sign-in or sign-out).
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //this if will get executed for the fraction of sec took to load firebase properly
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Splashscreen();
          }
          //if snapshod has data like if we have token, we are loged in, then chat screen will be displayed
          if (snapshot.hasData) {
            return ChatScreen();
          }
          //if we dont have data then authscreen will be displayed
          return AuthScreen();
        },
      ),
    );
  }
}
