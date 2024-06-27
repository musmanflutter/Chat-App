import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//this will give us an instance/ global var which we can use
//FirebaseAuth is The entry point of the Firebase Authentication SDK
//now we can use this variable to get access to various method of firebase
final _fireBase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  var _enteredUsername = '';

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }

    //if data is valid then this code will be executed
    //.save ensures onsave works well in textformfield
    _form.currentState!.save();

    //we are using try/catch method for error handling
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        await _fireBase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      }
      //this else will be executed if we are not in login mode, means we are signing up
      else {
        //we use await here because createUserWithEmailAndPassword returns a future value
        //now we are able to use that variable
        //if we werent using sdk, we had to manually setup this method for creating users
        //with different exceptions thrown when lets say email is invalid
        //createUserWithEmailAndPassword is a method provided by sdk that bts sents http
        // request to firebase, this will create user with email and password
        final userCredentials = await _fireBase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

//FirebaseStorage gives firebase storage
//.ref gives us reference to firebase cloud storage
//.child creates a new path, first we created a folder name user_images then crate a file inside it of type jpg
//.user gives us some data about the user
//.uuid will store image only of specific user containign that id
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        //putFile Upload a [File] from the filesystem. The file must exist.
        await storageRef.putFile(_selectedImage!);
        //getDownloadURL Fetches a long lived download URL for this object.
        final imageUrl = await storageRef.getDownloadURL();
        //FirebaseFirestore : The entry point for accessing a [FirebaseFirestore].
        //it works with collection(think of it as a folder)
        //we created a collection(folder) named Users here
        //doc: actual data entries. think of it as a file inside folder
        //doc can have a fixed name using '' or a dynamic name jst like we used it
        //set: means which data will be in that data entry.
        //in short we created a folder then a file inside it then some data into it.
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl
        });
      }
    }
    //we are using a bit diffferent version of catch here
    //by on we tell which type of error will be handled so we say FirebaseAuthException
    //now only firebase related error will be handled here
    on FirebaseAuthException catch (error) {
      //.code is the optional code to accommodate the message.
      //we got email-already-in-use auto by createuser.. method, this is an exception, an error
      //that will be thrown auto by that method if same email is in use
      if (error.code == 'email-already-in-use') {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
      );
      setState(() {
        _isAuthenticating = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(1),
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 30,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  width: 200,
                  child: Image.asset('assets/images/chat.png'),
                ),
                Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //if we are creating an account, only then this will be shown
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  //here we will be getting the image from userimagepicker file and storing it in selectedimage
                                  _selectedImage = pickedImage;
                                },
                              ),
                            //means only show these text form fields if we are not signing in
                            //instead we are signing up
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.trim().length < 4) {
                                    return 'Please enter atleast 4 characters';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredUsername = newValue!;
                                },
                              ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Email Adress'),
                              keyboardType: TextInputType.emailAddress,
                              //this will stop the keyboard auto correvting the words
                              autocorrect: false,
                              //this will ensure that first letter of email wont be capital
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email adress';
                                }
                                //if value is valid then we return null, nothing
                                return null;
                              },
                              //onsaved contains value got by user.
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              },
                            ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Password'),
                              //this will hide the password while being typed.
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be atleast 6 characters long';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredPassword = newValue!;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            //if data is not loaded, its loding then show a spinner
                            if (_isAuthenticating) const CircularProgressIndicator(),
                            //while image is being uploaded, buttons wont show
                            //they will only show if we have uploaded, we have finished loading data
                            if (!_isAuthenticating)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                onPressed: _submit,
                                child: Text(_isLogin ? 'Login' : 'SignUp'),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  //=! will reverse Islogan, if its true, it will make it false, if its false,
                                  // it will make it true
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create an account'
                                    : 'Already have an account'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
