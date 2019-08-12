import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';

import 'credit_card_bloc.dart';
import 'profile_tile.dart';

class CreditCardPage extends StatefulWidget {
  final ValueChanged<String> result;

  CreditCardPage({this.result});

  @override
  _CreditCardPageState createState() => new _CreditCardPageState();
}

class _CreditCardPageState extends State<CreditCardPage> {
  BuildContext _context;
  CreditCardBloc cardBloc;
  MaskedTextController ccMask =
      MaskedTextController(mask: "0000 0000 0000 0000");
  MaskedTextController expMask = MaskedTextController(mask: "00/00");
  TextEditingController cvvControl = new TextEditingController();
  FocusNode _focus2 = new FocusNode();
  bool _isCVV = false;

  void initState() {
    super.initState();
    _focus2.addListener(() {
      if (_focus2.hasFocus)
        setState(() {
          _isCVV = true;
        });
      else
        setState(() {
          _isCVV = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    cardBloc = CreditCardBloc();

    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: new Text('Credit Card'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.help,
              color: Colors.white,
            ),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            creditCardWidget(),
            fillEntries(),
            Container(height: 40)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          widget.result('success');
          Navigator.pop(context);
        },
        //backgroundColor: Colors.transparent,
        icon: Icon(
          Icons.payment,
          color: Colors.white,
        ),
        label: Text(
          "Continue",
          //style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget cardEntries() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StreamBuilder<String>(
                stream: cardBloc.ccOutputStream,
                initialData: "**** **** **** ****",
                builder: (context, snapshot) {
                  snapshot.data.length > 0
                      ? ccMask.updateText(snapshot.data)
                      : null;
                  return !_isCVV
                      ? Text(
                          snapshot.data.length > 0
                              ? snapshot.data
                              : "**** **** **** ****",
                          style: TextStyle(color: Colors.white, fontSize: 22.0),
                        )
                      : Container(width: 0, height: 0);
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                StreamBuilder<String>(
                    stream: cardBloc.expOutputStream,
                    initialData: "MM/YY",
                    builder: (context, snapshot) {
                      snapshot.data.length > 0
                          ? expMask.updateText(snapshot.data)
                          : null;
                      return !_isCVV
                          ? ProfileTile(
                              textColor: Colors.white,
                              title: "Expiry",
                              subtitle: snapshot.data.length > 0
                                  ? snapshot.data
                                  : "MM/YY",
                            )
                          : Container(width: 0, height: 0);
                    }),
                SizedBox(
                  width: 200.0,
                ),
                StreamBuilder<String>(
                    stream: cardBloc.cvvOutputStream,
                    initialData: "***",
                    builder: (context, snapshot) => _isCVV
                        ? ProfileTile(
                            textColor: Colors.white,
                            title: "CVV",
                            subtitle: snapshot.data.length > 0
                                ? snapshot.data
                                : "***",
                          )
                        : Container(width: 0, height: 0)),
              ],
            ),
          ],
        ),
      );

  Widget fillEntries() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: ccMask,
              keyboardType: TextInputType.number,
              maxLength: 19,
              onChanged: (out) => cardBloc.ccInputSink.add(ccMask.text),
              decoration: InputDecoration(
                  labelText: "Card Number", border: OutlineInputBorder()),
            ),
            TextField(
              controller: expMask,
              keyboardType: TextInputType.number,
              maxLength: 5,
              onChanged: (out) => cardBloc.expInputSink.add(expMask.text),
              decoration: InputDecoration(
                  labelStyle: TextStyle(),
                  labelText: "MM/YY",
                  border: OutlineInputBorder()),
            ),
            TextField(
              controller: cvvControl,
              keyboardType: TextInputType.number,
              maxLength: 3,
              focusNode: _focus2,
              onChanged: (out) => cardBloc.cvvInputSink.add(out),
              decoration: InputDecoration(
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  labelText: "CVV (on the back of the card)",
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      );

  Widget creditCardWidget() {
    var deviceSize = MediaQuery.of(_context).size;
    return Container(
      height: deviceSize.height * 0.3,
      color: Colors.grey.shade300,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 3.0,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  // new Color.fromRGBO(103, 218, 255, 1.0),
                  // new Color.fromRGBO(3, 169, 244, 1.0),
                  // new Color.fromRGBO(0, 122, 193, 1.0),
                  Colors.blueGrey.shade800,
                  Colors.blue,
                ])),
              ),
              Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "assets/images/map.png",
                  fit: BoxFit.cover,
                ),
              ),
              _isCVV
                  ? Positioned(
                      top: 20,
                      child: SizedBox(
                          height: 50,
                          width: MediaQuery.of(_context).size.width,
                          child: Row(children: <Widget>[
                            Expanded(child: Container(color: Colors.black))
                          ])))
                  : Container(width: 0, height: 0),
              MediaQuery.of(_context).orientation == Orientation.portrait
                  ? cardEntries()
                  : FittedBox(
                      child: cardEntries(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
