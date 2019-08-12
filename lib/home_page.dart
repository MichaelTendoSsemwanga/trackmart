import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

import 'about.dart';
import 'chat.dart';
import 'contact.dart';
import 'settings.dart';
import 'support.dart';
import 'map.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onSignedout;
  final String currentUserId;

  HomePage({this.onSignedout, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primaryColor: const Color(0xff004d40),
        primaryColorDark: const Color(0xff005B9A),
        accentColor: const Color(0xff005B9A),
      ),
      title: "Trackmart",
      home: new TabbedGuy(
        onSignedout: this.onSignedout,
        currentUserId: this.currentUserId,
      ),
    );
  }
}

class TabbedGuy extends StatefulWidget {
  const TabbedGuy({this.onSignedout, this.currentUserId});

  final VoidCallback onSignedout;
  final String currentUserId;

  @override
  _TabbedGuyState createState() =>
      new _TabbedGuyState(currentUserId: this.currentUserId);
}

class _TabbedGuyState extends State<TabbedGuy>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  double quantity = 1;
  DatabaseReference databaseReference;
  FirebaseDatabase database;
  cf.Firestore firestore;

  // final formKey = new GlobalKey<FormState>();
  // final key = new GlobalKey<ScaffoldState>();
  final TextEditingController _filter = new TextEditingController();
  final TextEditingController _namefilter = new TextEditingController();
  final TextEditingController _moneyController = new TextEditingController();
  final TextEditingController _moneyController2 = new TextEditingController();
  FocusNode myFocusNode;
  FocusNode myFocusNode2;
  final dio = new Dio();
  String _searchText = "";
  String _nameText = "";
  String _unit = 'Tonne';
  final String _product = 'Sand';
  String _paymnt = 'Mobile money';
  List<String> _units = ['Truck', 'Tonne'];
  List<String> _payment = ['Mobile money', 'Cash'];
  List<Driver> filteredDrivers = new List<Driver>();
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Trackmart');
  List<HistoryItem> _history = <HistoryItem>[];
  List<HistoryItem> _filteredHistory = <HistoryItem>[];
  FocusNode _focus = new FocusNode();
  FocusNode _focus2 = new FocusNode();
  static int _selected = -1;
  bool _isTransacting = false;
  bool _forexError = false;
  bool _isConverting = false;
  double rate;
  SharedPreferences prefs;
  final String currentUserId;
  String currentUserName;
  String currentUserPhoto;
  String currentUserPhone;
  static double currentLat;
  static double currentLong;

  //TODO: Don't draw anything before all loading is done, all thens have completed
  bool _stillLoading = true;

  _TabbedGuyState({this.currentUserId});

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _startup().then((value) {
      if (mounted)
        setState(() {
          _stillLoading = !value;
        });
    }).catchError((e) {
      print(e.toString());
      //sho(e.toString(), context);
      if (mounted)
        setState(() {
          _stillLoading = false;
        });
    });
  }

  _selectDriver(String id) {
    _tabController.animateTo(1);
    databaseReference.child('Drivers').child(id).once().then((d) {
      var values = d.value;
      filteredDrivers = [
        Driver(
            name: values['displayName'],
            phone: values['phoneNo'],
            id: values['id'].toString(),
            lat: values['lat'],
            long: values['long'],
            select: () => select(0),
            deselect: deselect)
      ];
      select(0);
    });
  }

  select(index) {
    print(index);
    filteredDrivers[index].selected = true;
    filteredDrivers[index].deselect = deselect;
    if (mounted)
      setState(() {
        _selected = index;
      });
  }

  deselect() {
    if (mounted)
      setState(() {
        _selected = -1;
      });
  }

  _updateLocation(Position position) {
    if (mounted)
      setState(() {
        currentLat = position.latitude;
        currentLong = position.longitude;
      });
    databaseReference
        .child('buyers')
        .child(currentUserId)
        .update({
          'lat': position.latitude,
          'long': position.longitude,
        })
        .then((v) {})
        .catchError((e) {
          print(e.toString());
        });
  }

  Future<bool> _startup() async {
    database = FirebaseDatabase.instance;
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    databaseReference = database.reference();
    await cf.Firestore.instance.settings(persistenceEnabled: true);
    firestore = cf.Firestore.instance;
    prefs = await SharedPreferences.getInstance();
    currentUserName = prefs.getString('displayName');
    currentUserPhone = prefs.getString('phoneNo');
    currentUserPhoto = prefs.getString('photoUrl');
    var geolocator = Geolocator();
    await geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((value) {
      Position position = value;
      _updateLocation(position);
      var locationOptions =
          LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
      geolocator.getPositionStream(locationOptions).listen((Position position) {
        _updateLocation(position);
      });
    });
    _moneyController.addListener(() {
      if (_moneyController.text.isEmpty) {
        if (mounted)
          setState(() {
            _moneyController2.text = "";
          });
      } else if (_focus.hasFocus) {
        {
          _moneyController2.text =
              (double.parse(_moneyController.text) * (rate ?? 0))
                  .toStringAsFixed(
                      0); //TODO: misbehaving error invalid double on parse
        }
      }
    });
    _moneyController2.addListener(() {
      if (_moneyController2.text.isEmpty) {
        if (mounted)
          setState(() {
            _moneyController.text = "";
          });
      } else if (_focus2.hasFocus) {
        {
          if (rate != null)
            _moneyController.text =
                (double.parse(_moneyController2.text) / rate)
                    .toStringAsFixed(2);
        }
      }
    });
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        if (mounted)
          setState(() {
            _searchText = "";
            _filteredHistory = _history;
          });
      } else {
        if (mounted)
          setState(() {
            _searchText = _filter.text;
          });
      }
    });
    _moneyController.text = '$quantity';
    updateRate();
    _moneyController2.text = '${(quantity * (rate ?? 0)).toStringAsFixed(0)}';
    _getHistory();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 1);
    myFocusNode = FocusNode();
    myFocusNode2 = FocusNode();
    myFocusNode2.addListener(() {
      if (mounted) setState(() {});
    });
    return true;
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    myFocusNode2.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _minus() {
    if (double.parse(_moneyController.text) >= 1) if (mounted)
      setState(() {
        _moneyController.text =
            '${(double.tryParse(_moneyController.text) ?? 0) - 1}';
        _moneyController2.text =
            '${(double.parse(_moneyController.text) * (rate ?? 0)).toStringAsFixed(0)}';
      });
  }

  void _plus() {
    if (mounted)
      setState(() {
        _moneyController.text =
            '${(double.tryParse(_moneyController.text) ?? 0) + 1}';
        _moneyController2.text =
            '${((double.tryParse(_moneyController.text) ?? 0) * (rate ?? 0)).toStringAsFixed(0)}';
      });
  }

  Widget build(BuildContext context) {
    return _stillLoading
        ? SafeArea(
            child: Scaffold(
                body: Container(
            color: Colors.white,
            child: Center(
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Icon(
                Icons.local_shipping,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              Container(
                margin: EdgeInsets.only(bottom: 8),
                width: 200,
                child: LinearProgressIndicator(),
              ),
              Center(
                child: Text('Trackmart',
                    style: TextStyle(
                        fontSize: 20, color: Theme.of(context).accentColor)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Text('Order • Track • Build',
                      style: TextStyle(
                          fontSize: 17, color: Theme.of(context).accentColor)),
                ),
              ),
            ])),
          )))
        : Scaffold(
            drawer: Drawer(
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new SettingsPage(
                                      firestore: firestore,
                                    )));
                      },
                      child: Center(
                          child: Column(children: <Widget>[
                        Material(
                          child: currentUserPhoto != null
                              ? CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).accentColor),
                                    ),
                                    width: 80.0,
                                    height: 80.0,
                                    //padding: EdgeInsets.all(15.0),
                                  ),
                                  imageUrl: currentUserPhoto,
                                  width: 80.0,
                                  height: 80.0,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 80.0,
                                ),
                          borderRadius: BorderRadius.all(Radius.circular(40.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(currentUserName??'',
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Theme.of(context).accentColor)),
                        ),
                      ])),
                    ),
                    decoration: BoxDecoration(),
                  ),
                  ListTile(
                    title: Text('Help'),
                    trailing: new Icon(
                      Icons.help,
                      color: Theme.of(context).accentColor,
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => new SupportPage()));
                    },
                  ),
                  ListTile(
                    title: Text('Contact'),
                    trailing: new Icon(
                      Icons.phone,
                      color: Theme.of(context).accentColor,
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => new ContactPage()));
                      // Update the state of the app.
                      // ...
                    },
                  ),
                  ListTile(
                    title: Text('About Trackmart'),
                    trailing: new Icon(
                      Icons.local_shipping,
                      color: Theme.of(context).accentColor,
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => new About()));
                    },
                  ),
                  ListTile(
                    title: Text('Invite'),
                    trailing: new Icon(
                      Icons.share,
                      color: Theme.of(context).accentColor,
                    ),
                    onTap: () {
                      Share.share(
                          'You can order for Sand delivery using Trackmart app. Check it out at https://play.google.com/Trackmartapp?uid=${currentUserId}');
                      print(
                          'You can order for Sand delivery using Trackmart app. Check it out at https://play.google.com/Trackmartapp?uid=${currentUserId}');
                    },
                  ),
                  ListTile(
                    title: Text('Log out'),
                    trailing: new Icon(
                      Icons.exit_to_app,
                      color: Theme.of(context).accentColor,
                    ),
                    onTap: () {
                      widget.onSignedout();
                    },
                  ),
                ],
              ),
            ),
            appBar: _buildBar(context),
            body: new InkWell(
              onTapDown: (t) {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  new Column(
                    //modified
                    children: <Widget>[
                      //new
                      new Flexible(
                        child: _buildContacts(), //new
                      ),
                      //new
                    ], //new
                  ),
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: new Column(//new
                          children: <Widget>[
                        Expanded(
                          child: ListView(
                            children: <Widget>[
                              //new Text('Enter name/number:'),                       //new
                              new Container(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: 8.0, bottom: 8, right: 8),
                                  child: new Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: new TextField(
                                          onChanged: (value) {
                                            //if(myFocusNode2.hasFocus)
                                            if (value.isEmpty) {
                                              if (mounted)
                                                setState(() {
                                                  //_selected=-1;
                                                  _nameText = "";
                                                  //filteredDrivers = names;
//          _filteredContacts=_messages;
//          _filteredHistory=_history;
                                                });
                                            } else {
                                              if (mounted)
                                                setState(() {
                                                  _selected = -1;
                                                  _nameText = _namefilter.text;
                                                });
                                            }
                                          },
                                          focusNode: myFocusNode2,
                                          decoration: InputDecoration(
                                              //border: OutlineInputBorder(),
                                              labelText:
                                                  'Enter merchant\'s name or number:',
                                              suffix: InkWell(
                                                  child: Icon(
                                                    Icons.close,
                                                    color: Theme.of(context)
                                                        .primaryColorDark,
                                                  ),
                                                  onTap: () {
                                                    _namefilter.clear();
                                                    _nameText = '';
                                                    FocusScope.of(context)
                                                        .requestFocus(
                                                            new FocusNode());
                                                  })),
                                          controller: _namefilter,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: 150,
                                width: MediaQuery.of(context).size.width,
                                child: _buildDrivers(),
                              ),
                              new Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Card(
                                      child: Container(
                                        padding: new EdgeInsets.only(
                                            top: 8.0, bottom: 8),
                                        child: new Column(
                                          children: <Widget>[
                                            new Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: <Widget>[
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.remove,
                                                      size: 32,
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                    ),
                                                    onPressed: _minus,
                                                  ),
                                                  Expanded(
                                                    child: new TextField(
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          InputDecoration(
                                                        //border: OutlineInputBorder(),
                                                        labelText: 'Quantity',
                                                      ),
                                                      controller:
                                                          _moneyController,
                                                      focusNode: _focus,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.add,
                                                      size: 32,
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                    ),
                                                    onPressed: _plus,
                                                  ),
                                                ]),
                                            new Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  new DropdownButton<String>(
                                                    value: _unit,
                                                    onChanged:
                                                        (String newValue) {
                                                      if (mounted)
                                                        setState(() {
                                                          _unit = newValue;
                                                        });
                                                      //prefs.setString('unit', _unit);
                                                      _getPrice(newValue)
                                                          .then((value) {
                                                        if (mounted)
                                                          setState(() {
                                                            updateRate();
                                                          });
                                                      });
                                                    },
                                                    items: _units.map<
                                                        DropdownMenuItem<
                                                            String>>(
                                                        (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(value),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Card(
                                      child: Container(
                                        padding: new EdgeInsets.all(8.0),
                                        child: new Column(
                                          children: <Widget>[
                                            new TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                //border: OutlineInputBorder(),
                                                labelText: 'Amount payed:',
                                              ),
                                              controller: _moneyController2,
                                              focusNode: _focus2,
                                            ),
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                new DropdownButton<String>(
                                                  value: _paymnt,
                                                  onChanged: (String newValue) {
                                                    if (mounted)
                                                      setState(() {
                                                        _paymnt = newValue;
                                                        //updateRate();
                                                      });
                                                  },
                                                  items: _payment.map<
                                                      DropdownMenuItem<
                                                          String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              new Row(children: <Widget>[
                                Expanded(
                                    child: Text(
                                        '1 $_unit of $_product costs UGX ${(rate ?? 0).toStringAsFixed(0)}',
                                        key: Key('rate'),
                                        textAlign: TextAlign.right)),
                                _isConverting
                                    ? new IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          if (mounted)
                                            setState(() {
                                              _isConverting = false;
                                              _forexError = true;
                                            });
                                        },
                                      )
                                    : new IconButton(
                                        icon: Icon(
                                          Icons.refresh,
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                        onPressed: () {
                                          updateRate();
                                        }),
                              ]),
                              _forexError || _isConverting
                                  ? new Row(children: <Widget>[
                                      Expanded(
                                          child: Text(
                                              _isConverting
                                                  ? 'Fetching...'
                                                  : 'Can\'t connect!',
                                              style: TextStyle(
                                                  color: _forexError
                                                      ? Colors.red
                                                      : Colors.blue),
                                              textAlign: TextAlign.right)),
                                    ])
                                  : Container(width: 0, height: 0),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  //Expanded(child: Container()),
                                  MaterialButton(
                                    key: Key('request'),
                                    //) RaisedButton(
                                    //disabledColor:Colors.lightBlue,
                                    color: Theme.of(context).primaryColor,
                                    onPressed: _isConverting || _forexError
                                        ? null
                                        : () {
                                            if (_selected < 0) select(0);
                                            _showDialog();
                                          },
                                    child: Padding(
                                      padding: EdgeInsets.all(9),
                                      child: Text('Request',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        /*MediaQuery.of(context).viewInsets.bottom==0?balance():Container(),*/
                      ])),
                  new Column(
                    //modified
                    children: <Widget>[
                      //new
                      new Flexible(
                        //new
                        child: _buildHistory(), //new
                      ), //new
                    ], //new
                  ),
                ],
              ),
            ),
          );
  }

  Order makeOrderNow() {
    return Order(
      destlat: currentLat,
      destlong: currentLong,
      driverId: filteredDrivers[_selected].id,
      driverName: filteredDrivers[_selected].name,
      driverPhone: filteredDrivers[_selected].phone,
      userId: currentUserId,
      userName: currentUserName,
      userPhone: currentUserPhone,
      quantity: double.parse(_moneyController.text),
      payment: _paymnt,
      price: (rate ?? 0),
      unit: _unit,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  _result(String message) {
    print(message);
    //TODO: tell server
    if (message == 'success') {
      final fido3 = makeOrderNow();
    }
    if (message == 'fail') {
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Unable to send',
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Perhaps you need to:'),
                  Text(''),
                  Text(
                    'Check your card details',
                    style: TextStyle(color: Theme.of(context).accentColor),
                  ),
                  Text(''),
                  Text('...and try again.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Check'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      actions: <Widget>[
        IconButton(
          icon: _searchIcon,
          onPressed: _searchPressed,
        ),
        IconButton(
          icon: Icon(Icons.map),
          onPressed: () {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new MapPage2(
                          ulat: _TabbedGuyState.currentLat,
                          ulong: _TabbedGuyState.currentLong,
                          selectDriver: _selectDriver,
                        )));
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: ('Chats')),
          Tab(text: ('Request')),
          Tab(text: ('Orders')),
        ],
      ),
      title: _appBarTitle,
    );
  }

  static showModal(text, sent_context) {
    showDialog(
        context: sent_context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text(text),
            content: LinearProgressIndicator(),
            contentPadding: EdgeInsets.all(10.0),
          );
        });
  }

  _requestDelivery(Order order, BuildContext context) async {
    showModal('Requesting...', context);
    String key = 'O:${DateTime.now().millisecondsSinceEpoch}';
    await databaseReference
        .child('Drivers')
        .child(order.driverId)
        .child('requests')
        .update({
      key: order.toMap(currentUserId),
    });
    await databaseReference
        .child('buyers')
        .child(currentUserId)
        .child('requests')
        .update({
      key: order.toMap(currentUserId),
    });
    Navigator.of(context).pop();
  }

  _showDialog() async {
    if (_selected >= 0 &&
        rate != null &&
        double.tryParse(_moneyController.text) != null)
      showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(
              'Confirm',
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            content: Text(
              'Request delivery of ${_moneyController.text} $_unit${double.parse(_moneyController.text) > 1 ? 's' : ''} of $_product from ${filteredDrivers[_selected].name} for ${_moneyController2.text}',
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    deselect();
                    Navigator.of(context).pop();
                  }),
              new FlatButton(
                child: const Text('Request'),
                onPressed: () {
                  //TODO://
                  _requestDelivery(
                          new Order(
                              destlat: currentLat,
                              destlong: currentLong,
                              userId: currentUserId,
                              userName: currentUserName,
                              driverId: filteredDrivers[_selected].id,
                              driverName: filteredDrivers[_selected].name,
                              driverPhone: filteredDrivers[_selected].phone,
                              price: (rate ?? 0),
                              payment: _paymnt,
                              quantity: double.parse(_moneyController.text),
                              unit: _unit,
                              timestamp: DateTime.now().millisecondsSinceEpoch),
                          context)
                      .then((v) {
                    Navigator.of(context).pop();
                    deselect();
                    _tabController.animateTo(2);
                  });
                },
              ),
            ],
          );
        },
      );
    else {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Unable to send',
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Perhaps you need to:'),
                  Text(''),
                  _selected < 0
                      ? Text(
                          '• Enter a number or select a driver',
                          style:
                              TextStyle(color: Theme.of(context).accentColor),
                        )
                      : Container(width: 0, height: 0),
                  ((double.tryParse(_moneyController.text) == null)
                      ? Text(
                          '• Enter a quantity to order',
                          style:
                              TextStyle(color: Theme.of(context).accentColor),
                        )
                      : Container(width: 0, height: 0)),
                  ((rate == null)
                      ? Text(
                          '• Connect to the internet',
                          style:
                              TextStyle(color: Theme.of(context).accentColor),
                        )
                      : Container(width: 0, height: 0)),
                  Text(''),
                  Text('...and try again.'),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Check'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildContacts() {
    return Stack(
      children: <Widget>[
        // List
        Container(
          child: StreamBuilder(
            stream: firestore.collection('drivers').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).accentColor),
                  ),
                );
              } else {
                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) =>
                      buildItem(context, snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                );
              }
            },
          ),
        ),
        Positioned(
          child: isLoading
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).accentColor)),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : Container(),
        )
      ],
    );
  }

  Widget buildItem(BuildContext context, cf.DocumentSnapshot document) {
    return document['displayName']
            .toLowerCase()
            .contains(_searchText.toLowerCase())
        ? Container(
            child: FlatButton(
              child: Row(
                children: <Widget>[
                  Material(
                    child: document['photoUrl'] != null
                        ? CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).accentColor),
                              ),
                              width: 50.0,
                              height: 50.0,
                              //padding: EdgeInsets.all(15.0),
                            ),
                            imageUrl: document['photoUrl'],
                            width: 50.0,
                            height: 50.0,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            //color: greyColor,
                          ),
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  Flexible(
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            child: Text(
                              '${document['displayName']}',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(left: 5.0),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Chat(
                              peerName: document['displayName'],
                              store: firestore,
                              peerId: document.documentID,
                              peerAvatar: document['photoUrl'],
                            )));
              },
              padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
            ),
            margin: EdgeInsets.only(left: 5.0, right: 5.0),
          )
        : Container(
            width: 0,
            height: 0,
          );
  }

  _buildInTransit() {
    return StreamBuilder(
      stream: databaseReference
          .child('buyers')
          .child(currentUserId)
          .child('transit')
          .onValue,
      //TODO: on value changes, chill streambuilder, listen and if(mounted)setState on names.
      builder: (context, snap) {
        if (snap.hasData &&
            !snap.hasError &&
            snap.data.snapshot.value != null) {
//taking the data snapshot.
          //DataSnapshot snapshot = snap.data.snapshot;
          List<HistoryItem> items = [];
//it gives all the documents in this list.
          //List<Map<String,dynamic>> _list=;
//Now we're just checking if document is not null then add it to another list called "item".
//I faced this problem it works fine without null check until you remove a document and then your stream reads data including the removed one with a null value(if you have some better approach let me know).
          Map<String, dynamic> map =
              snap.data.snapshot.value.cast<String, dynamic>();
          map.forEach((key, values) {
            if (values != null) {
              items.add(Order(
                getHistory: _getHistory,
                key: key,
                type: Order.TRANSIT,
                userId: values['userId'],
                userName: values['userName'],
                driverId: values['driverId'],
                driverName: values['driverName'],
                driverPhone: values['driverPhone'],
                quantity: values['quantity'].toDouble(),
                payment: values['payment'],
                price: values['price'].toDouble(),
                unit: values['unit'],
                timestamp: values['timestamp'],
              ).toHistoryItem());
            }
          });
          return items.isNotEmpty
              ? Column(children: <Widget>[
                  InkWell(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('In transit', style: TextStyle(fontSize: 16)),
                            IconButton(
                                icon: Icon(transit
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down),
                                onPressed: () {
                                  if (mounted)
                                    setState(() {
                                      transit = !transit;
                                    });
                                })
                          ]),
                      onTap: () {
                        if (mounted)
                          setState(() {
                            transit = !transit;
                          });
                      }),
                  transit
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items,
                        )
                      : Container(width: 0, height: 0),
                ])
              : Container(width: 0, height: 0);
        } else {
          return Container(width: 0, height: 0);
        }
      },
    );
  }

  bool requested = true;
  bool transit = true;
  bool delivered = true;

  Widget _buildHistory() {
    if (_searchText.isNotEmpty) {
      List<HistoryItem> tempList = new List<HistoryItem>();
      for (int i = 0; i < _history.length; i++) {
        if (_history[i]
                .driver
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            _history[i]
                .date
                .toLowerCase()
                .contains(_searchText.toLowerCase())) {
          tempList.add(_history[i]);
        }
      }
      _filteredHistory = tempList;
    }
    return SingleChildScrollView(
        child: Column(children: <Widget>[
      StreamBuilder(
        stream: databaseReference
            .child('buyers')
            .child(currentUserId)
            .child('requests')
            .onValue,
        //TODO: on value changes, chill streambuilder, listen and if(mounted)setState on names.
        builder: (context, snap) {
          if (snap.hasData &&
              !snap.hasError &&
              snap.data.snapshot.value != null) {
//taking the data snapshot.
            //DataSnapshot snapshot = snap.data.snapshot;
            List<HistoryItem> items = [];
//it gives all the documents in this list.
            //List<Map<String,dynamic>> _list=;
//Now we're just checking if document is not null then add it to another list called "item".
//I faced this problem it works fine without null check until you remove a document and then your stream reads data including the removed one with a null value(if you have some better approach let me know).
            Map<String, dynamic> map =
                snap.data.snapshot.value.cast<String, dynamic>();
            map.forEach((key, values) {
              if (values != null) {
                items.add(Order(
                  type: Order.REQUESTED,
                  key: key,
                  userId: values['userId'],
                  userName: values['userName'],
                  driverId: values['driverId'],
                  driverName: values['driverName'],
                  driverPhone: values['driverPhone'],
                  quantity: values['quantity'].toDouble(),
                  payment: values['payment'],
                  price: values['price'].toDouble(),
                  unit: values['unit'],
                  timestamp: values['timestamp'],
                ).toHistoryItem());
              }
            });
            return items.isNotEmpty
                ? Column(children: <Widget>[
                    InkWell(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Requested', style: TextStyle(fontSize: 16)),
                              IconButton(
                                  icon: Icon(requested
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down),
                                  onPressed: () {
                                    if (mounted)
                                      setState(() {
                                        requested = !requested;
                                      });
                                  })
                            ]),
                        onTap: () {
                          if (mounted)
                            setState(() {
                              requested = !requested;
                            });
                        }),
                    requested
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items,
                          )
                        : Container(width: 0, height: 0),
                    //Divider(),
                  ])
                : Container(width: 0, height: 0);
          } else {
            return Padding(
                padding: EdgeInsets.all(16),
                child: Text('No requested deliveries'));
          }
        },
      ),
      _buildInTransit(),
      InkWell(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Delivered', style: TextStyle(fontSize: 16)),
                IconButton(
                    icon: Icon(delivered
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down),
                    onPressed: () {
                      if (mounted)
                        setState(() {
                          delivered = !delivered;
                        });
                    })
              ]),
          onTap: () {
            if (mounted)
              setState(() {
                delivered = !delivered;
              });
          }),
      delivered
          ? _filteredHistory.length > 0
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _filteredHistory,
                )
              : Text(
                  'No delivered orders to display',
                  textAlign: TextAlign.center,
                )
          : Container(width: 0, height: 0),
    ]));
  }

  Widget _buildDrivers() {
    if (_selected != -1) {
      return filteredDrivers[_selected];
    }
//Now you can use stream builder to get the data.
    return StreamBuilder(
      stream: databaseReference
          .child('Drivers')
          .orderByChild('status')
          .equalTo(true)
          .onValue,
      //TODO: on value changes, chill streambuilder, listen and if(mounted)setState on names.
      builder: (context, snap) {
        if (snap.hasData &&
            !snap.hasError &&
            snap.data.snapshot.value != null) {
//taking the data snapshot.
          //DataSnapshot snapshot = snap.data.snapshot;
          List<Driver> items = [];
//it gives all the documents in this list.
          //List<Map<String,dynamic>> _list=;
//Now we're just checking if document is not null then add it to another list called "item".
//I faced this problem it works fine without null check until you remove a document and then your stream reads data including the removed one with a null value(if you have some better approach let me know).
          Map<String, dynamic> map =
              snap.data.snapshot.value.cast<String, dynamic>();
          int i = 0;
          map.forEach((key, values) {
            if (values != null) {
              int index = i;
              items.add(Driver(
                  name: values['displayName'],
                  phone: values['phoneNo'],
                  id: values['id'].toString(),
                  lat: values['lat'],
                  long: values['long'],
                  select: () => select(index),
                  deselect: deselect));
            }
            i++;
          });
          filteredDrivers = items;
          if (_selected == -1 && _nameText.isNotEmpty) {
            List<Driver> tempList = [];
            int limit = 0;
            for (int i = 0; i < items.length && limit < 30; i++) {
              if (items[i]
                      .name
                      .toLowerCase()
                      .contains(_nameText.toLowerCase()) ||
                  items[i]
                      .phone
                      .toLowerCase()
                      .contains(_nameText.toLowerCase())) {
                tempList.add(items[i]);
                limit++;
              }
            }
            items = tempList;
          }
          return items.isEmpty
//return sizedbox if there's nothing in database.
              ? SizedBox()
//otherwise return a list of widgets.
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return items[index];
                  },
                );
        } else if (!snap.hasData) {
          return Center(child: CircularProgressIndicator());
        } else if (snap.data.snapshot.value == null) {
          return Center(child: Text('No drivers'));
        } else
          return Center(child: Text('A problem occured!'));
      },
    );
  }
/*
  Widget _buildDriver(Driver name, int index) {
    return SizedBox(
      width: 140,
      child: Material(
          child: InkWell(
        onTap: () {
          select(index);
        },
        child: name,
      )),
    );
  }
*/

  void _searchPressed() {
    if (mounted)
      setState(() {
        if (this._searchIcon.icon == Icons.search) {
          if (_tabController.index == 1) _tabController.animateTo(0);
          this._searchIcon = new Icon(Icons.close);
          this._appBarTitle = new TextField(
            focusNode: myFocusNode,
            controller: _filter,
            decoration: new InputDecoration(
                //prefixIcon: new Icon(Icons.search),
                hintText:
                    'Search ${_tabController.index == 0 ? 'chats' : _tabController.index == 2 ? 'orders' : '...'}'),
          );
        } else {
          this._searchIcon = new Icon(Icons.search);
          this._appBarTitle = new Text('Trackmart');
          //filteredDrivers = names;
          _filteredHistory = _history;
          _filter.clear();
        }
      });
  }

  updateRate() async {
    rate = null;
    double value = await _getPrice(_unit);
    if (value != null) if (mounted)
      setState(() {
        rate = value;
        _moneyController2.text =
            ((double.tryParse(_moneyController.text) ?? 0) * rate)
                .toStringAsFixed(0);
      });
    prefs.setDouble('forex', (rate ?? 0));
  }

  Future<double> _getPrice(String unit) async {
    //if (curr1 == curr2) return 1;
    if (mounted)
      setState(() {
        _isConverting = true;
      });
    try {
      final response = await dio.get(
          'https://us-central1-instant-money-uganda.cloudfunctions.net/quest?q=$unit');

      if (response.data['response'] != null) {
        if (mounted)
          setState(() {
            _isConverting = false;
            _forexError = false;
          });
        return response.data['response'].toDouble();
      } else
        throw new Exception();
    } catch (e) {
      if (mounted)
        setState(() {
          _isConverting = false;
          _forexError = true;
        });
      print(e);
    }
  }

  void _getHistory() async {
    Future<List<HistoryItem>> transactions() async {
      final Future<Database> database = openDatabase(
        path.join(await getDatabasesPath(), 'history.db'),
        onCreate: (db, version) {
          return db.execute(
              "CREATE TABLE history(timestamp DATETIME DEFAULT CURRENT_TIMESTAMP PRIMARY KEY, driver TEXT, amount INTEGER, driverId TEXT, quantity TEXT, payment TEXT, date TEXT, unit TEXT)");
        },
        version: 1,
      );
      final Database db = await database;
      final List<Map<String, dynamic>> maps =
          await db.query('history', orderBy: 'timestamp DESC');
      return List.generate(maps.length, (i) {
        return HistoryItem(
          type: Order.DELIVERED,
          driverId: maps[i]['driverId'],
          quantity: double.parse(maps[i]['quantity']),
          payment: maps[i]['payment'],
          unit: maps[i]['unit'],
          driver: maps[i]['driver'],
          date: maps[i]['date'],
          amount: maps[i]['amount'].toString(),
        );
      });
    }

    List<HistoryItem> tempList = await transactions();
    if (mounted)
      setState(() {
        _history = tempList;
        _filteredHistory = _history;
      });
  }
}

class HistoryItem extends StatefulWidget {
  HistoryItem(
      {this.getHistory,
      this.type,
      this.orderKey,
      this.driver,
      this.driverId,
      this.userId,
      this.quantity,
      this.payment,
      this.amount,
      this.unit,
      this.date,
      this.driverPhone});
  final int type;
  final String driver;
  final String driverId;
  final String driverPhone;
  final String userId;
  final String amount;
  final String payment;
  final double quantity;
  final String unit;
  final String date;
  final String orderKey;
  final VoidCallback getHistory;
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'driverId': driverId,
      'driver': driver,
      'quantity': quantity,
      'payment': payment,
      'date': date,
      'unit': unit,
      'amount': int.parse(amount)
    };
  }

  Future<void> insertHistory() async {
    final Future<Database> database = openDatabase(
      path.join(await getDatabasesPath(), 'history.db'),
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE history(timestamp DATETIME DEFAULT CURRENT_TIMESTAMP PRIMARY KEY, driver TEXT, amount INTEGER, driverId TEXT, quantity TEXT, payment TEXT, date TEXT, unit TEXT)");
      },
      version: 1,
    );
    final Database db = await database;
    await db.insert(
      'history',
      toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    getHistory();
    //_TabbedGuy.
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return HistoryItemState();
  }
}

class HistoryItemState extends State<HistoryItem> {
  int distance;
  String avatar;
  double lat;
  double long;
  HistoryItemState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cf.Firestore.instance
        .collection('drivers')
        .document(widget.driverId)
        .get()
        .then((d) {
      if (mounted)
        setState(() {
          avatar = d['photoUrl'];
        });
    });
    if (widget.type != Order.DELIVERED)
      FirebaseDatabase.instance
          .reference()
          .child('Drivers')
          .child(widget.driverId)
          .onValue
          .listen((e) {
        Map<String, dynamic> map = e.snapshot.value.cast<String, dynamic>();
        lat = map['lat'].toDouble();
        long = map['long'].toDouble();
        Geolocator()
            .distanceBetween(_TabbedGuyState.currentLat,
                _TabbedGuyState.currentLong, lat, long)
            .then((value) {
          if (mounted)
            setState(() {
              distance = value.toInt();
            });
        });
      });
  }

  info(name, avatar, distance, phone, driverId) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: SizedBox(
              height: 150,
              child: Driver(
                lat: lat,
                long: long,
                name: name,
                avatar: avatar,
                distance: distance,
                phone: phone,
                id: driverId,
                selected: true,
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == Order.DELIVERED
        ? Column(
            children: <Widget>[
              InkWell(
                onTap: () {
                  info(
                      widget.driver,
                      avatar,
                      '${distance != null ? ((distance) / 1000).toStringAsFixed(2) + ' km' : ''}',
                      widget.driverPhone,
                      widget.driverId);
                },
                child: Container(
                  margin: EdgeInsets.only(left: 8, right: 8),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            info(
                                widget.driver,
                                avatar,
                                '${distance != null ? ((distance) / 1000).toStringAsFixed(2) + ' km' : ''}',
                                widget.driverPhone,
                                widget.driverId);
                          },
                          child: Material(
                            child: avatar != null
                                ? CachedNetworkImage(
                                    placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).accentColor),
                                      ),
                                      width: 50.0,
                                      height: 50.0,
                                      //padding: EdgeInsets.all(15.0),
                                    ),
                                    imageUrl: avatar,
                                    width: 50.0,
                                    height: 50.0,
                                    fit: BoxFit.cover,
                                  )
                                : new CircleAvatar(
                                    child: widget.driver == null
                                        ? Icon(
                                            Icons.account_circle,
                                            size: 50.0,
                                            //color: greyColor,
                                          )
                                        : new Text(widget.driver[0],
                                            style: TextStyle(fontSize: 30)),
                                    radius: 25),
                            borderRadius:
                                BorderRadius.all(Radius.circular(25.0)),
                            clipBehavior: Clip.hardEdge,
                          ),
                        ),
                      ),
                      Expanded(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(widget.driver ?? '',
                                style: Theme.of(context).textTheme.subhead),
                            new Container(
                              margin: const EdgeInsets.only(top: 5.0),
                              child: new Text(widget.quantity == null
                                  ? ''
                                  : '${widget.quantity} ${widget.unit}'),
                            ),
                          ],
                        ),
                      ),
                      new Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Container(
                            margin: const EdgeInsets.only(bottom: 5.0),
                            child: new Text(widget.amount ?? ''),
                          ),
                          new Text(widget.date ?? ''),
                        ],
                      ),
                      /*IconButton(
                        icon: Icon(
                          Icons.info,
                          color: Theme.of(context).accentColor,
                        ),
                        onPressed: null),*/
                    ],
                  ),
                ),
              ),
              Divider()
            ],
          )
        : Card(
            child: Padding(
              padding: EdgeInsets.only(top: 8, left: 8, right: 8),
              child: Column(
                children: <Widget>[
                  new InkWell(
                    onTap: () {
                      info(
                          widget.driver,
                          avatar,
                          '${distance != null ? ((distance) / 1000).toStringAsFixed(2) + ' km' : ''}',
                          widget.driverPhone,
                          widget.driverId);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              info(
                                  widget.driver,
                                  avatar,
                                  '${distance != null ? ((distance) / 1000).toStringAsFixed(2) + ' km' : ''}',
                                  widget.driverPhone,
                                  widget.driverId);
                            },
                            child: Material(
                              child: avatar != null
                                  ? CachedNetworkImage(
                                      placeholder: (context, url) => Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.0,
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Theme.of(context).accentColor),
                                        ),
                                        width: 50.0,
                                        height: 50.0,
                                        //padding: EdgeInsets.all(15.0),
                                      ),
                                      imageUrl: avatar,
                                      width: 50.0,
                                      height: 50.0,
                                      fit: BoxFit.cover,
                                    )
                                  : new CircleAvatar(
                                      child: widget.driver == null
                                          ? Icon(
                                              Icons.account_circle,
                                              size: 50.0,
                                              //color: greyColor,
                                            )
                                          : new Text(widget.driver[0],
                                              style: TextStyle(fontSize: 30)),
                                      radius: 25),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(25.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                          ),
                        ),
                        /*new Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            info(
                                widget.driver,
                                avatar,
                                '${distance != null ? ((distance) / 1000).toStringAsFixed(2) : '_'} km',
                                widget.driverPhone,
                                widget.driverId);
                          },
                          child: new CircleAvatar(
                            child: Text(widget.driver[0]),
                          ),
                        ),
                      ),*/
                        Expanded(
                          child: new Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              new Text(
                                  '${widget.driver ?? ''} (${distance != null ? ((distance) / 1000).toStringAsFixed(2) + ' km' : ''})',maxLines: 1,
                                  style: Theme.of(context).textTheme.subhead),
                              new Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                child: new Text(widget.quantity == null
                                    ? ''
                                    : '${widget.quantity} ${widget.unit}${widget.quantity > 1 ? 's' : ''}'),
                              ),
                            ],
                          ),
                        ),
                        new Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(widget.date),
                            new Container(
                              margin: const EdgeInsets.only(top: 5.0),
                              child: new Text(widget.amount ?? ''),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      /*FlatButton.icon(
                          label: Text('Info'),
                          icon: Icon(
                            Icons.info,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: null),*/
                      FlatButton.icon(
                        label: Text('Cancel'),
                        icon: Icon(
                          Icons.cancel,
                          color: Theme.of(context).accentColor,
                        ),
                        onPressed: () => widget.type == Order.REQUESTED
                            ? _cancelOrder(widget.orderKey, context)
                            : _cancelTransitOrder(widget.orderKey,
                                context), /*_infoOn(orderKey,driverId)*/
                      ),
                      widget.type == Order.REQUESTED
                          ? Container(
                              width: 0,
                              height: 0,
                            )
                          : widget.type == Order.TRANSIT
                              ? FlatButton.icon(
                                  label: Text('Track'),
                                  icon: Icon(
                                    Icons.pin_drop,
                                    color: Theme.of(context).accentColor,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        new MaterialPageRoute(
                                            builder: (context) => new MapPage(
                                                driverId: widget.driverId,
                                                driver: widget.driver,
                                                ulat:
                                                    _TabbedGuyState.currentLat,
                                                ulong:
                                                    _TabbedGuyState.currentLong,
                                                dlat: lat,
                                                dlong: long)));
                                  }, /*_infoOn(orderKey,driverId)*/
                                )
                              /*: FlatButton.icon(
                                      label: Text('Complete'),
                                      icon: Icon(
                                        Icons.check_circle_outline,
                                        color: Theme.of(context).accentColor,
                                      ),
                                      onPressed: () {
                                        _finishOrder(widget.orderKey, context);
                                      }, */ /*_infoOn(orderKey,driverId)*/ /*
                                    )*/
                              : Container(width: 0, height: 0),
                      widget.type == Order.TRANSIT && (distance ?? 101) < 100
                          ? FlatButton.icon(
                              label: Text('Complete'),
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).accentColor,
                              ),
                              onPressed: () {
                                _finishOrder(widget.orderKey, context);
                              }, /*_infoOn(orderKey,driverId)*/
                            )
                          : Container(width: 0, height: 0),
                    ],
                  ),
                ],
              ),
            ),
          );
    //Divider()
    /*],
    );*/
  }

  _cancelTransitOrder(String orderKey, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Cancel order\n$orderKey?'),
              Text('Driver: ${widget.driver}')
            ],
          ),
          actions: <Widget>[
            FlatButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
            ),
            //TODO:Replace all FlatButton with FlatButton.icon
            FlatButton.icon(
              onPressed: () {
                _deleteTransitOrder(orderKey, context).then((v) {
                  //Fluttertoast.showToast(msg: 'Delete successful');
                  Navigator.of(context).pop();
                });
              },
              icon: Icon(Icons.cancel),
              label: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  _cancelOrder(String orderKey, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Cancel order\n$orderKey?'),
              Text('Driver: ${widget.driver}')
            ],
          ),
          actions: <Widget>[
            FlatButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
            ),
            //TODO:Replace all FlatButton with FlatButton.icon
            FlatButton.icon(
              onPressed: () {
                _deleteOrder(orderKey, context).then((v) {
                  //Fluttertoast.showToast(msg: 'Delete successful');
                  Navigator.of(context).pop();
                });
              },
              icon: Icon(Icons.cancel),
              label: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  _finishOrder(String orderKey, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Complete order\n$orderKey?'),
              Text('Driver: ${widget.driver}'),
              Text('Give ${widget.driver} a rating'),
              //StatefulWidgetBuilder(context,),
              MyDialogContent()
              //new StarRating(rating: 0),
            ],
          ),
          actions: <Widget>[
            FlatButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
            ),
            //TODO:Replace all FlatButton with FlatButton.icon
            FlatButton.icon(
              onPressed: () async {
                _TabbedGuyState.showModal('Finishing...', context);
                if (MyDialogContent.rating > 0) {
                  final cf.DocumentReference postRef = cf.Firestore.instance
                      .document('drivers/${widget.driverId}');
                  cf.Firestore.instance
                      .runTransaction((cf.Transaction tx) async {
                    cf.DocumentSnapshot postSnapshot = await tx.get(postRef);
                    if (postSnapshot.exists) {
                      await tx.update(postRef, <String, dynamic>{
                        'totalrating': (postSnapshot.data['totalrating'] ?? 0) +
                            MyDialogContent.rating
                      });
                      await tx.update(postRef, <String, dynamic>{
                        'totalnumber':
                            (postSnapshot.data['totalnumber'] ?? 0) + 1
                      });
                    } else
                      print('No driver ${widget.driverId}');
                  });
                }
                await FirebaseDatabase.instance
                    .reference()
                    .child('buyers')
                    .child(widget.userId)
                    .child('transit')
                    .child(orderKey)
                    .remove()
                    .then((v) {
                  Navigator.of(context).pop();
                  widget.insertHistory().then((v) {
                    Navigator.of(context).pop();
                  });
                });
              },
              icon: Icon(Icons.check_circle_outline),
              label: Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  _deleteTransitOrder(String orderKey, context) async {
    _TabbedGuyState.showModal('Cancelling...', context);
    FirebaseDatabase database = new FirebaseDatabase();
    DatabaseReference dataRef = database.reference();
    await dataRef
        .child('Drivers')
        .child(widget.driverId)
        .child('transit')
        .child(orderKey)
        .remove();
    await dataRef
        .child('buyers')
        .child(widget.userId)
        .child('transit')
        .child(orderKey)
        .remove();
    Navigator.of(context).pop();
  }

  _deleteOrder(String orderKey, context) async {
    _TabbedGuyState.showModal('Cancelling...', context);
    FirebaseDatabase database = new FirebaseDatabase();
    DatabaseReference dataRef = database.reference();
    await dataRef
        .child('Drivers')
        .child(widget.driverId)
        .child('requests')
        .child(orderKey)
        .remove();
    await dataRef
        .child('buyers')
        .child(widget.userId)
        .child('requests')
        .child(orderKey)
        .remove();
    Navigator.of(context).pop();
  }
}

class Request extends StatelessWidget {
  final Order order;

  Request(this.order);

  @override
  Widget build(BuildContext context) {}
}

class Driver extends StatefulWidget {
  Driver(
      {this.distance,
      this.avatar,
      this.id,
      this.name,
      this.phone,
      this.lat,
      this.long,
      this.deselect,
      this.select,
      this.selected = false});

  final String name;
  String avatar;
  final String phone;
  final String id;
  double lat;
  double long;
  String distance;
  bool selected;
  VoidCallback deselect;
  VoidCallback select;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return DriverState(
        distance: distance, lat: this.lat, long: this.long, avatar: avatar);
  }
}

class DriverState extends State<Driver> {
  double lat;
  double long;
  String distance;
  String avatar;
  double totalrating;
  int totalnumber;

  DriverState({this.distance, this.long, this.lat, this.avatar});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cf.Firestore.instance
        .collection('drivers')
        .document(widget.id)
        .get()
        .then((d) {
      if (mounted)
        setState(() {
          avatar = d['photoUrl'];
          totalnumber = d['totalnumber'];
          totalrating = d['totalrating'];
        });
      widget.avatar = d['photoUrl'];
    });
    if (lat != null)
      Geolocator()
          .distanceBetween(_TabbedGuyState.currentLat,
              _TabbedGuyState.currentLong, lat, long)
          .then((value) {
        if (mounted)
          setState(() {
            distance = (value / 1000).toStringAsFixed(2) + ' km';
          });
      });
  }

  _launchURL() async {
    if (await canLaunch('tel:${widget.phone}')) {
      await launch('tel:${widget.phone}');
    } else {
      throw 'Could not launch tel:${widget.phone}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selected)
      return Card(
        shape: new RoundedRectangleBorder(
            side: new BorderSide(
                color: Theme.of(context).accentColor, width: 2.0),
            borderRadius: BorderRadius.circular(4.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              leading: Material(
                child: avatar != null
                    ? CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).accentColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          //padding: EdgeInsets.all(15.0),
                        ),
                        imageUrl: avatar,
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.cover,
                      )
                    : /* Icon(
              Icons.account_circle,
              size: 50.0,
              //color: greyColor,
            ),*/
                    new CircleAvatar(
                        child: widget.name == null
                            ? Icon(
                                Icons.account_circle,
                                size: 60.0,
                                //color: greyColor,
                              )
                            : new Text(widget.name[0],
                                style: TextStyle(fontSize: 30)),
                        radius: 30),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              title: Text(widget.name ?? ''),
              subtitle: Text((distance ??
                  '') + /*((distance!=null&&totalrating!=null)?' — ':'')+*/ '${totalrating != null ? ' Stars: ${(totalrating / totalnumber).toStringAsFixed(2)}/5' : ''}'),
              trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    if (mounted)
                      setState(() {
                        if (widget.deselect != null)
                          widget.deselect();
                        else
                          Navigator.of(context).pop();
                      });
                  }),
              selected: true,
              onTap: () {
                widget.deselect();
              },
            ),
            new Row(
              //mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: widget.lat!=null?FlatButton.icon(
                          label: Text('Route'),
                          icon: Icon(
                            Icons.pin_drop,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => new MapPage(
                                        driverId: widget.id,
                                        driver: widget.name,
                                        ulat: _TabbedGuyState.currentLat,
                                        ulong: _TabbedGuyState.currentLong,
                                        dlat: lat,
                                        dlong: long)));
                          }):Container(
                    width: 0,
                    height: 0,
                  ),
                ),
                Expanded(
                  child: FlatButton.icon(
                      label: Text('Text'),
                      icon: Icon(
                        Icons.textsms,
                        color: Theme.of(context).accentColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Chat(
                                      peerName: widget.name,
                                      peerId: widget.id,
                                      peerAvatar: avatar,
                                    )));
                        /*_infoOn(orderKey,driverId)*/
                      }),
                ),
                widget.phone!=null?Expanded(
                  child: FlatButton.icon(
                      label: Text('Call'),
                      icon: Icon(
                        Icons.phone,
                        color: Theme.of(context).accentColor,
                      ),
                      onPressed: _launchURL),
                ):Container(width: 0,height: 0,),
              ],
            ),
          ],
        ),
      );
    else
      return SizedBox(
        width: 140,
        child: Material(
          child: InkWell(
            onTap: () {
              widget.select();
            },
            child: new Card(
              child: new Stack(
                children: <Widget>[
                  widget.phone == null
                      ? Container(
                          width: 0,
                          height: 0,
                        )
                      : Align(
                          child: IconButton(
                              icon: Icon(
                                Icons.phone,
                                color: Theme.of(context).accentColor,
                              ),
                              onPressed: _launchURL),
                          alignment: AlignmentDirectional.bottomEnd,
                        ),
                  Align(
                    child: IconButton(
                        icon: Icon(
                          Icons.textsms,
                          color: Theme.of(context).accentColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Chat(
                                        peerName: widget.name,
                                        peerId: widget.id,
                                        peerAvatar: avatar,
                                      )));
                        }),
                    alignment: AlignmentDirectional.bottomStart,
                  ),
                  Center(
                      child: Container(
                    padding: new EdgeInsets.all(4.0),
                    child: new Column(
                      //crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: Material(
                              child: avatar != null
                                  ? CachedNetworkImage(
                                      placeholder: (context, url) => Container(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.0,
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Theme.of(context).accentColor),
                                        ),
                                        width: 70.0,
                                        height: 70.0,
                                        //padding: EdgeInsets.all(15.0),
                                      ),
                                      imageUrl: avatar,
                                      width: 70.0,
                                      height: 70.0,
                                      fit: BoxFit.cover,
                                    )
                                  : new CircleAvatar(
                                      child: widget.name == null
                                          ? Icon(
                                              Icons.account_circle,
                                              size: 70.0,
                                              //color: greyColor,
                                            )
                                          : new Text(widget.name[0],
                                              style: TextStyle(fontSize: 35)),
                                      radius: 35),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: new Text(
                              widget.name == null
                                  ? ''
                                  : widget.name.split(' ')[0],
                              maxLines: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 4.0,
                          ),
                          child: new Text(
                            distance ?? '',
                          ),
                        ),
                      ],
                    ),
                  ))
                ],
              ),
            ),
          ),
        ),
      );
  }
}

class Order {
  final String userName;
  final String userId;
  final String driverName;
  final String driverPhone;
  final String userPhone;
  final String userAvatar;
  final String driverId;
  final double price;
  final String payment;
  final double quantity;
  final String unit;
  final String key;
  final VoidCallback getHistory;
  var timestamp;
  final double destlat;
  final double destlong;
  final int type;
  static final int REQUESTED = 1;
  static final int TRANSIT = 2;
  static final int DELIVERED = 3;

  Order(
      {this.getHistory,
      this.destlat,
      this.destlong,
      this.type,
      this.key,
      this.userId,
      this.userName,
      this.driverId,
      this.driverName,
      this.userAvatar,
      this.driverPhone,
      this.userPhone,
      this.quantity,
      this.payment,
      this.price,
      this.unit,
      this.timestamp});

  HistoryItem toHistoryItem() {
    return new HistoryItem(
      driverPhone: driverPhone,
      getHistory: getHistory,
      type: type,
      driverId: driverId,
      userId: userId,
      orderKey: key,
      driver: driverName,
      quantity: quantity,
      payment: payment,
      date: DateFormat('dd MMM kk:mm')
          .format(DateTime.fromMillisecondsSinceEpoch((timestamp))),
      amount: (price * quantity).toStringAsFixed(0),
      unit: unit,
    );
  }

  Map<String, dynamic> toMap(String uid) {
    return {
      'userId': userId,
      'userName': userName,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'userPhone': userPhone,
      'userAvatar': userAvatar,
      'quantity': quantity,
      'payment': payment,
      'price': price,
      'unit': unit,
      'timestamp': timestamp,
      'userId': uid,
      'destlat': destlat,
      'destlong': destlong,
    };
  }
}

class MyDialogContent extends StatefulWidget {
  MyDialogContent({this.context});
  static double rating = 0;
  BuildContext context;

  @override
  _MyDialogContentState createState() =>
      new _MyDialogContentState(rating: rating);
}

class _MyDialogContentState extends State<MyDialogContent> {
  double rating;
  _MyDialogContentState({this.rating});
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SmoothStarRating(
        allowHalfRating: true,
        onRatingChanged: (v) {
          MyDialogContent.rating = v;
          setState(() {
            rating = v;
          });
        },
        starCount: 5,
        rating: rating,
        size: 40.0,
        color: Theme.of(context).accentColor, //Colors.green,
        borderColor: Theme.of(context).primaryColor,
        spacing: 0.0);
  }
}
