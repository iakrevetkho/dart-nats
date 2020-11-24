import 'package:flutter/material.dart';
import 'package:dart_nats_client/dart_nats_client.dart' as nats;

void main() => runApp(MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: MyStatefulWidget(),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  /// Default constructor
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  Future<nats.Client> _brockerConnection = new Future(() async {
    // Init NATS client
    var client = nats.Client();
    print("Start client.connect");
    await client.connect('10.0.2.2',
        port: 4222, timeout: 2, retry: false, retryInterval: 1);
    print("Client connected");
    // Subscribe on "echo" topic
    var sub = client.sub('echo');

    // test infinite loop
    while (true) {
      // Wait data in subscription stream
      var msg = await sub.poll();
      var date = DateTime.now();
      print("$date: Received msg: " + msg.string);
      // Publish response
      msg.respondString('response on ' + msg.string);
      print("$date: Response sent");
    }

    // client.unSub(sub);
    // client.close();

    // print("return client");
    // return client;
  });

  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.headline2,
      textAlign: TextAlign.center,
      child: FutureBuilder<nats.Client>(
        future:
            _brockerConnection, // a previously-obtained Future<nats.Client> or null
        builder: (BuildContext context, AsyncSnapshot<nats.Client> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            children = <Widget>[
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Result: ${snapshot.data}'),
              )
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          } else {
            children = <Widget>[
              SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Connecting to NATS broker...'),
              )
            ];
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          );
        },
      ),
    );
  }
}
