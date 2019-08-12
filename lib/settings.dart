import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'const.dart';

class SettingsPage extends StatefulWidget {
  final Firestore firestore;
  final DatabaseReference database;

  SettingsPage({this.firestore, this.database});

  @override
  _SettingsPageState createState() =>
      new _SettingsPageState(firestore: firestore, database: database);
}

class _SettingsPageState extends State<SettingsPage> {
  /*bool _monitor = true;
  bool _lights = false;
  bool _kitchen = false;
  bool _bedroom = false;*/
  final Firestore firestore;
  final DatabaseReference database;

  _SettingsPageState({this.firestore, this.database});

  bool _changed = false;
  String _unit = 'Tonne';
  List<String> _units = ['Tonne', 'Truck'];
  List<String> _quality = ['Fine', 'Coarse'];
  String _qualty = 'Fine';
  SharedPreferences prefs;
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;
  String id;
  String displayName;
  String aboutMe;
  String photoUrl;

  bool isLoading = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();

  void _submit() {}

  @override
  initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _unit = (prefs.getString('unit') ?? 'Tonne');
      _qualty = (prefs.getString('quality') ?? 'Fine');
    });
    id = prefs.getString('id') ?? '';
    displayName = prefs.getString('displayName') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';

    controllerNickname = new TextEditingController(text: displayName);
    controllerAboutMe = new TextEditingController(text: aboutMe);

    // Force refresh input
    setState(() {});
  }

  Future getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    String fileName = id;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          firestore.collection('users').document(id).updateData({
            'displayName': displayName,
            'aboutMe': aboutMe,
            'photoUrl': photoUrl
          });
          firestore.collection('buyers').document(id).updateData({
            'displayName': displayName,
            'aboutMe': aboutMe,
            'photoUrl': photoUrl
          }).then((data) async {
            await prefs.setString('photoUrl', photoUrl);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Upload success");
          }).catchError((err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: err.toString());
          });
        }, onError: (err) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'This file is not an image');
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    firestore.collection('users').document(id).updateData({
      'displayName': displayName,
      'aboutMe': aboutMe,
      'photoUrl': photoUrl
    });
    firestore.collection('buyers').document(id).updateData({
      'displayName': displayName,
      'aboutMe': aboutMe,
      'photoUrl': photoUrl
    }).then((data) async {
      await prefs.setString('displayName', displayName);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('photoUrl', photoUrl);
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Update success");
      Navigator.of(context).pop();
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  List<Widget> _buildForm(BuildContext context) {
    Form form = new Form(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Avatar
            Container(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    (avatarImageFile == null)
                        ? (photoUrl != ''
                            ? Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          themeColor),
                                    ),
                                    width: 90.0,
                                    height: 90.0,
                                    padding: EdgeInsets.all(20.0),
                                  ),
                                  imageUrl: photoUrl,
                                  width: 90.0,
                                  height: 90.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(45.0)),
                                clipBehavior: Clip.hardEdge,
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 90.0,
                                color: greyColor,
                              ))
                        : Material(
                            child: Image.file(
                              avatarImageFile,
                              width: 90.0,
                              height: 90.0,
                              fit: BoxFit.cover,
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(45.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                    IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        //color: primaryColor.withOpacity(0.5),
                      ),
                      onPressed: getImage,
                      padding: EdgeInsets.all(30.0),
                      //splashColor: Colors.transparent,
                      //highlightColor: greyColor,
                      iconSize: 30.0,
                    ),
                  ],
                ),
              ),
              width: double.infinity,
              margin: EdgeInsets.all(20.0),
            ),
            Container(
              child: Text(
                'Name',
                //style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
            ),
            Container(
              child: Theme(
                data: Theme.of(context).copyWith(primaryColor: primaryColor),
                child: TextField(
                  decoration: InputDecoration(
                    //hintText: 'First name',
                    contentPadding: new EdgeInsets.all(5.0),
                    //hintStyle: TextStyle(color: greyColor),
                  ),
                  controller: controllerNickname,
                  onChanged: (value) {
                    setState(() {
                      _changed = true;
                    });
                    displayName = value;
                  },
                  focusNode: focusNodeNickname,
                ),
              ),
              margin: EdgeInsets.only(left: 30.0, right: 30.0),
            ),

            // About me
            Container(
              child: Text(
                'About me',
                //style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              margin: EdgeInsets.only(left: 10.0, top: 30.0, bottom: 5.0),
            ),
            Container(
              child: Theme(
                data: Theme.of(context).copyWith(primaryColor: primaryColor),
                child: TextField(
                  decoration: InputDecoration(
                    //hintText: 'Fun, like travel and play PES...',
                    contentPadding: EdgeInsets.all(5.0),
                    //hintStyle: TextStyle(color: greyColor),
                  ),
                  controller: controllerAboutMe,
                  onChanged: (value) {
                    setState(() {
                      _changed = true;
                    });
                    aboutMe = value;
                  },
                  focusNode: focusNodeAboutMe,
                ),
              ),
              margin: EdgeInsets.only(left: 30.0, right: 30.0),
            ),

            Container(
              height: 8,
            ),
            _changed
                ? new ListTile(
                    leading: Icon(Icons.warning),
                    title: const Text('Tap disc icon and restart app to save changes'),
                  )
                : isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container(
                        width: 0,
                        height: 0,
                      ),
          ],
        ),
        padding: EdgeInsets.only(left: 15.0, right: 15.0),
      ),
    );

    var l = new List<Widget>();
    l.add(form);
    return l;
  }

  _leave() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(
            icon: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (_changed)
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              title: Text('Unsaved changes will be lost'),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text('Lose'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _leave();
                                    //Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                    child: Text('Save'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      handleUpdateData();
                                    }),
                              ]);
                        });
                  else
                    Navigator.of(context).pop();
                }),
            onPressed: () {
              //Navigator.of(context).pop();
            }),
        title: new Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: handleUpdateData,
          )
        ],
      ),
      body: new Stack(
        children: _buildForm(context),
      ),
    );
  }
}
