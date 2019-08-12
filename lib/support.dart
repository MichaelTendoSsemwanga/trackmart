import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact.dart';

class SupportPage extends StatefulWidget {
  @override
  _SupportPageState createState() => new _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool _q1 = false;
  bool _q2 = false;
  bool _q3 = false;
  bool _q4 = false;
  bool _q5 = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Help'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.language,
              color: Colors.white,
            ),
            onPressed: () async {
              if (await canLaunch('http://sandtrackapp.com/faq')) {
                await launch('http://sandtrackapp.com/faq');
              } else {
                throw 'Could not launch http://www.sandtrackapp.com/faq';
              }
            },
          )
        ],
      ),
      body: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: <Widget>[
          //Container(height:20),

          InkWell(
              child: Row(children: <Widget>[
                Text('What does Trackmart do?', style: TextStyle(fontSize: 16)),
                IconButton(
                    icon:
                        Icon(_q1 ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                    onPressed: () {
                      setState(() {
                        _q1 = !_q1;
                      });
                    })
              ]),
              onTap: () {
                setState(() {
                  _q1 = !_q1;
                });
              }),
          _q1
              ? Text(
                  'We mediate between truck drivers and consumers to facilitate order requests for construction materials in the comfort of your preffered location, along with tracking to enable you concentrate on building your future')
              : Container(width: 0, height: 0),
          Divider(),
          Text('If this didn\'t solve your problem,'),
          RaisedButton(
            color: Theme.of(context).accentColor,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new ContactPage()));
              //_showDialog();
            },
            child: Text('Contact Us', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

class Hyperlink extends StatelessWidget {
  final String _url;
  final String _text;

  Hyperlink(this._url, this._text);

  _launchURL() async {
    if (await canLaunch(_url)) {
      await launch(_url);
    } else {
      throw 'Could not launch $_url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        _text,
        style: TextStyle(
          decoration: TextDecoration.underline,
          color: Theme.of(context).accentColor,
        ),
      ),
      onTap: _launchURL,
    );
  }
}
