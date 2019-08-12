import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  LoginPage({this.onSignedIn, this.login});

  final ValueChanged<FirebaseUser> onSignedIn;
  final bool login;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new LoginPageState(login: this.login);
  }
}

enum FormType { login, register }

class LoginPageState extends State<LoginPage> {
  final FirebaseAuth fAuth = FirebaseAuth.instance;
  final formKey = new GlobalKey<FormState>();
  bool _obscureText = true;
  String _countryCode = '+254';
  String phoneNo;
  String email;
  String _pin;
  String _name;
  String smsCode;
  String verificationId;
  bool useEmail = false;
  bool login;
  bool _agreed = false;

  LoginPageState({this.login});

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleEmail() {
    setState(() {
      useEmail = !useEmail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.help,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
          title: Text('Welcome'),
          centerTitle: true,
        ),
        body: new GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: SingleChildScrollView(
              child: Center(
                child: new Container(
                  padding: EdgeInsets.all(16.0),
                  child: new Form(
                    key: formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.local_shipping,size:120,color: Theme.of(context).primaryColor,),
                          ),
                          Center(
                            child: Text('Trackmart',
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Theme.of(context).accentColor)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                              child: Text('Order • Track • Build',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Theme.of(context).accentColor)),
                            ),
                          ),
                          useEmail
                              ? new TextField(
                                  decoration: InputDecoration(
                                      labelText: "Enter email address"),

                                  //onSaved: (value) => phoneNo = value,
                                  onChanged: (value) {
                                    this.email = value;
                                  },
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    CountryCodePicker(
                                      onChanged: (value) {
                                        _countryCode = value.toString();
                                      },
                                      // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                                      initialSelection: 'KE',
                                      //favorite: ['+256', 'UG'],
                                      // optional. Shows only country name and flag
                                      showCountryOnly: false,
                                      // optional. Shows only country name and flag when popup is closed.
                                      //showOnlyCountryCodeWhenClosed: false,
                                      // optional. aligns the flag and the Text left
                                      alignLeft: false,
                                    ),
                                    Expanded(
                                      child: new TextField(
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                            labelText: "Enter phone number"),
                                        onChanged: (value) {
                                          this.phoneNo = value;
                                        },
                                      ),
                                    )
                                  ],
                                ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: new TextField(
                                  decoration: InputDecoration(
                                    //icon: IconButton(icon: new Icon(Icons.remove_red_eye)),
                                    labelText:
                                        '${login ? "Enter" : "Choose a"} password',
                                  ),
                                  obscureText: _obscureText,

                                  //onSaved: (value) => phoneNo = value,
                                  onChanged: (value) {
                                    this._pin = value;
                                  },
                                ),
                              ),
                              new FlatButton(
                                  onPressed: _toggle,
                                  child:
                                      new Text(_obscureText ? "Show" : "Hide"))
                            ],
                          ),
                          login
                              ? useEmail
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                          Padding(
                                              padding: new EdgeInsets.all(8.0),
                                              child: InkWell(
                                                  onTap: () async {
                                                    try {
                                                      await FirebaseAuth
                                                          .instance
                                                          .sendPasswordResetEmail(
                                                              email: email);
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                'Password reset'),
                                                            content: Text(
                                                                'A password reset link has been sent to $email. Check $email for further instructions on resetting your password'),
                                                            actions: <Widget>[
                                                              new FlatButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child:
                                                                    Text('OK'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    } catch (e) {
                                                      showMessageDialog(
                                                          e.message);
                                                    }
                                                  },
                                                  child: new Text(
                                                      'Forgot password?',
                                                      style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .accentColor))))
                                        ])
                                  : Container(
                                      width: 0,
                                      height: 0,
                                    )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                      ),
                                      onChanged: (value) {
                                        this._name = value;
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Checkbox(
                                            value: _agreed,
                                            onChanged: (value) {
                                              setState(() {
                                                _agreed = value;
                                              });
                                            }),
                                        Text('I agree to Trackmart '),
                                        InkWell(
                                          child: Text('Terms of use',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .accentColor)),
                                          onTap: () async {
                                            if (await canLaunch(
                                                'http://sandtrackapp.com/legal')) {
                                              await launch(
                                                  'http://sandtrackapp.com/legal');
                                            } else {
                                              print(
                                                  'Could not launch tel:+256700216707');
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: OutlineButton(
                              borderSide: BorderSide(
                                  color: Theme.of(context).accentColor),
                              //textColor: Theme.of(context).accentColor,
                              onPressed: (login || (!login && _agreed))
                                  ? !useEmail ? verifyPhone : verifyEmail
                                  : () {
                                      showMessageDialog(
                                          'Please agree to terms and conditions');
                                    },
                              color: Theme.of(context).accentColor,
                              child: Text('${login ? "Login " : " Sign up"}',
                                  style: TextStyle(
                                      color: Theme.of(context).accentColor)),
                            ),
                          ),
                          FlatButton(
                              onPressed: _toggleEmail,
                              child: new Text(
                                  'Use ${useEmail ? "Phone" : "Email"} instead')),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                  '${login ? "New to Trackmart?" : "Already have an account?"}'),
                              InkWell(
                                child: Text('${login ? " Sign up" : " Log in"}',
                                    style: TextStyle(
                                        color: Theme.of(context).accentColor)),
                                onTap: () {
                                  setState(() {
                                    login = !login;
                                  });
                                },
                              )
                            ],
                          ),
                        ]),
                  ),
                ),
              ),
            )));
  }

  saveUserDetails(FirebaseUser user) async {
    DatabaseReference dRef = FirebaseDatabase.instance.reference();
    Firestore fRef = Firestore.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', user.uid);
    await prefs.setString('displayName', _name);
    await prefs.setString('phoneNo', phoneNo!=null?(_countryCode+phoneNo):null);
    await prefs.setString('photoUrl', user.photoUrl);
    login = !(fRef.collection('buyers').document(user.uid)==null);
    if(login){
      print('old');
    Map<String, dynamic> map =
    (await fRef.collection('buyers').document(user.uid)?.get()).data;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', user.uid);
    await prefs.setString('displayName', map!=null?map['displayName']:_name);
    await prefs.setString('photoUrl', map!=null?map['photoUrl']:null);
    await prefs.setString('phoneNo', map!=null?map['phoneNo']:(phoneNo!=null?_countryCode+phoneNo:null));
    }
    else {
      print('new');
      await dRef.child('drivers').child(user.uid).set({
        'id': user.uid,
        'photoUrl': user.photoUrl,
        'displayName': _name,
        'phoneNo': (phoneNo!=null?_countryCode+phoneNo:null)
      });
      await fRef.collection('buyers').document(user.uid).setData({
        'id': user.uid,
        'displayName': _name,
        'photoUrl': user.photoUrl,
        'phoneNo': (phoneNo!=null?_countryCode+phoneNo:null)
      });
      await fRef.collection('users').document(user.uid).updateData({
        'displayName': _name,
        //'photoUrl': user.photoUrl,
        'phoneNo': (phoneNo!=null?_countryCode+phoneNo:null)
      });

    }
  }

  showMessageDialog(String message) {
    print(message);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Note'),
          content: Text(message??'Try again'),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  showErrorDialog(PlatformException e) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(e.message),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  showSimple(title, content) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(children: <Widget>[
                Container(
                  child: LinearProgressIndicator(),
                ),
                Text(content)
              ]),
            ),
            contentPadding: EdgeInsets.all(10.0),
          );
        });
  }

  Future<void> verifyEmail() async {
    if (login) {
      showSimple('Log in', 'Verifying user credentials...');
      try {
        FirebaseUser user = await fAuth.signInWithEmailAndPassword(
            email: email, password: _pin);
        if (user.isEmailVerified) {
          await saveUserDetails(user);
          Navigator.of(context).pop();
          widget.onSignedIn(user);
        } else {
          await user.sendEmailVerification();
          Navigator.of(context).pop();
          showMessageDialog(
              'Email is not verified, check $email for verification link');
        }
      } catch (e) {
        Navigator.of(context).pop();
        print(e.toString());
        showMessageDialog(e.message);
      }
    } else {
      showSimple('A moment', 'Creating your account...');
      try {
        FirebaseUser user = await fAuth.createUserWithEmailAndPassword(
            email: email, password: this._pin);
        await user.sendEmailVerification();
        Navigator.of(context).pop();
      } catch (e) {
        Navigator.of(context).pop();
        print(e.toString());
        //Navigator.of(context).pop();
        showMessageDialog(e.message);
        return;
      }

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return new StreamBuilder<FirebaseUser>(
              stream: fAuth.onAuthStateChanged,
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data.isEmailVerified
                      ? AlertDialog(
                          title: Text('Verification'),
                          content: Text('$email is verified'),
                          contentPadding: EdgeInsets.all(10.0),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Change email'),
                            ),
                            new FlatButton(
                              onPressed: () {
                                setState(() {
                                  login = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Log in'),
                            ),
                          ],
                        ) //MainPage()
                      : AlertDialog(
                          title: Text('Verification'),
                          content: Text('Check $email for verification link.'),
                          contentPadding: EdgeInsets.all(10.0),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Change email'),
                            ),
                            new FlatButton(
                              onPressed: () {
                                setState(() {
                                  login = true;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Log in'),
                            ),
                          ],
                        ); // VerifyEmailPage(user: snapshot.data);
                } else {
                  return AlertDialog(
                    title: Text('Waiting'),
                    content: CircularProgressIndicator(),
                    contentPadding: EdgeInsets.all(10.0),
                    actions: <Widget>[
                      new FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Change email'),
                      ),
                      new FlatButton(
                        onPressed: () {
                          //Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                }
              },
            );
          });
    }
  }

  Future<void> verifyPhone() async {
    if (login) {
      showSimple('Log in', 'Verifying user credentials...');
      try {
        FirebaseUser user = await fAuth.signInWithEmailAndPassword(
            email: _countryCode + phoneNo + '@sandtrackapp.com',
            password: _pin);
        await saveUserDetails(user);
        Navigator.of(context).pop();
        widget.onSignedIn(user);
      } catch (e) {
        Navigator.of(context).pop();
        print(e.toString());
        showMessageDialog(e.message);
      }
    } else {
      final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
        print('Autoretrieval tmed out');
        this.verificationId = verId;
      };
      final PhoneVerificationCompleted verifiedSuccess =
          (AuthCredential credential) async {
        showSimple('Success',
            'Retrieved SMS code... Saving user credentials...');
        try {
          FirebaseUser user = await fAuth.createUserWithEmailAndPassword(
              email: _countryCode + phoneNo + '@sandtrackapp.com',
              password: _pin);
          await saveUserDetails(user);
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          widget.onSignedIn(user);
        } catch (e) {
          try {
            FirebaseUser user = await fAuth.signInWithEmailAndPassword(
                email: _countryCode + phoneNo + '@sandtrackapp.com',
                password: _pin);
            login=true;
            await saveUserDetails(user);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            widget.onSignedIn(user);
          } catch (e) {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            showMessageDialog(e.message);
          }
        }
      };
      final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
        this.verificationId = verId;
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return new AlertDialog(
                title: Text(
                    'SMS Code has been sent to ${_countryCode + this.phoneNo}'),
                content: SingleChildScrollView(
                  child: ListBody(children: <Widget>[
                    TextField(
                        onChanged: (value) {
                          this.smsCode = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Enter code',
                        )),
                  ]),
                ),
                contentPadding: EdgeInsets.all(10.0),
                actions: <Widget>[
                  new FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Change number'),
                  ),
                  new FlatButton(
                    child: Text('Done'),
                    onPressed: () {
                      final AuthCredential credential =
                          PhoneAuthProvider.getCredential(
                        verificationId: verificationId,
                        smsCode: smsCode,
                      );
                      verifiedSuccess(credential);
                    },
                  ),
                ],
              );
            });
      };

      final PhoneVerificationFailed veriFailed = (AuthException exception) {
        print('${exception.message}');
        showMessageDialog(exception.message);
      };
      await fAuth.verifyPhoneNumber(
          phoneNumber: this._countryCode + this.phoneNo,
          codeAutoRetrievalTimeout: autoRetrieve,
          codeSent: smsCodeSent,
          timeout: const Duration(seconds: 15),
          verificationCompleted: verifiedSuccess,
          verificationFailed: veriFailed);
    }
  }
}
