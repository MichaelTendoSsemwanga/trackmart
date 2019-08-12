import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sandtrack/home_page.dart';
import 'login_page.dart';
//import 'chat.dart';
class RootPage extends StatefulWidget {
  //RootPage();
  @override
  State<StatefulWidget> createState() => RootPageState();
}

enum AuthStatus { notSignedIn, signedIn, loading }

class RootPageState extends State<RootPage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  AuthStatus authStatus = AuthStatus.loading;
  String currentUserId;
  bool login = false;
Firestore firestore;
  @override
  void initState() {
    //await Firestore.instance.settings(persistenceEnabled: true);
    firestore=Firestore.instance;
    super.initState();
    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      showNotification(message['notification']);
      //_handleMessage(message);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      //_handleMessage(message);
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      //_handleMessage(message);
      return;
    });
    configLocalNotification();
    FirebaseAuth.instance.currentUser().then((user) {
      setState(() {
        authStatus =
            user == null ? AuthStatus.notSignedIn : AuthStatus.signedIn;
        if (user != null) {
          currentUserId = user.uid;
          if (user.email[0] != '+'&&!user.isEmailVerified) {
            login=true;
            authStatus = AuthStatus.notSignedIn;
          }
        }
      });
    });
  }
/*void _handleMessage(Map<String,dynamic> message){
  var data = message['data'] ?? message;
  String type = data['type'];
  if(type=='request')
    requestDialog(message);
    if(type=='message')
      {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Chat(
                  peerName: data['peerName'],
                  store: firestore,
                  peerId: data['peerId'],
                  peerAvatar: data['peerAvatar'],
                )));
      }
  }*/
  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'com.example.sandtrack',
      'Trackmart',
      'Communication',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  requestDialog(message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            message['notification']['title'],
            style: TextStyle(color: Theme.of(context).accentColor),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message['notification']['body']),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton.icon(
              icon:Icon(Icons.cancel),
              label: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton.icon(
              icon:Icon(Icons.check),
              label: Text('Accept'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _signedIn(FirebaseUser user) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('A moment'),
            content: SingleChildScrollView(
              child: ListBody(children: <Widget>[
                Container(
                  child: LinearProgressIndicator(),
                ),
                Text(
                    'Setting things up...')
              ]),
            ),
            contentPadding: EdgeInsets.all(10.0),
          );
        });
    String token = await firebaseMessaging.getToken(); //.then((token){
    await FirebaseDatabase.instance
        .reference()
        .child('users')
        .child(user.uid)
        .update({
      'deviceToken': token,
    });
    await firestore.collection('users').document(user.uid).updateData({
      'pushToken': token,
    });
    Navigator.of(context).pop();
    setState(() {
      currentUserId = user.uid;
      authStatus = AuthStatus.signedIn;
    });
  }

  void _signedOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print(e.toString);
    }
    setState(() {
      authStatus = AuthStatus.notSignedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.notSignedIn:
        return new LoginPage(
          onSignedIn: _signedIn,
          login: this.login,
        );
      case AuthStatus.signedIn:
        return new HomePage(
          //auth: widget.auth,
          onSignedout: _signedOut,
          currentUserId: this.currentUserId,
        );
      case AuthStatus.loading:
        return new Scaffold(
          body: Center(
            child:
                //CircularProgressIndicator()
            Icon(Icons.local_shipping,size:120,color: Theme.of(context).primaryColor,),
          ),
        );
    }

    return new LoginPage();
  }
}
