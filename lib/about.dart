import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  @override
  _AboutState createState() => new _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('About Trackmart'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.language,
              color: Colors.white,
            ),
            onPressed: () async {
              if (await canLaunch('http://sandtrackapp.com')) {
                await launch('http://sandtrackapp.com');
              } else {
                throw 'Could not launch http://www.sandtrackapp.com';
              }
            },
          )
        ],
      ),
      body: new Center(
        child: Column(children: <Widget>[
          Container(height: 60),
          Icon(Icons.local_shipping,size:80,color: Theme.of(context).primaryColor,),
          Text('Property of:'),
          Text('Trackmart Technologies'),
          Hyperlink('http://www.sandtrackapp.com', 'sandtrackapp.com'),
          Text('Nairobi, Kenya'),
          Container(height: 20),
          Hyperlink('http://www.sandtrackapp.com/legal', 'Legal documentation'),
          Container(height: 20),
          Text('Designed and developed by:'),
          Text('Michael Tendo Ssemwanga'),
          Hyperlink('http://www.tendo.dev', 'tendo.dev'),
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
          color: Theme
              .of(context)
              .accentColor,
        ),
      ),
      onTap: _launchURL,
    );
  }
}
