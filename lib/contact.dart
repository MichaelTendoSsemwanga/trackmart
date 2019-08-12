import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPageState createState() => new _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Contact Us'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.phone,
              color: Colors.white,
            ),
            onPressed: () async {
              if (await canLaunch('tel:+256700216707')) {
                await launch('tel:+256700216707');
              } else {
                print('Could not launch tel:+256700216707');
              }
            },
          )
        ],
      ),
      body: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new Center(
          child: Column(children: <Widget>[
            Container(height: 60),
            Icon(Icons.local_shipping,size:80,color: Theme.of(context).primaryColor,),
            Text(
                'We suggest that you check out the support page in case of any issues.'),
            Text(
                'In case you were not able to solve your issue with the information in the support section,'),
            Text('We are here to help, any time of day'),
            Text('Call:'),
            Hyperlink('tel:+256700216707', '+256700216707'),
            Container(height: 20),
            Text('Email:'),
            Hyperlink(
                'mailto:support@sandtrackapp.com', 'support@sandtrackapp.com'),
            Container(height: 20),
            Text('Whatsapp:'),
            //Text('Michael Tendo Ssemwanga'),
            Hyperlink('http:wa.me/+256700216707', '+256700216707'),
          ]),
        ),
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
