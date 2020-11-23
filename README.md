# Dart-NATS 
A Dart client for the [NATS](https://nats.io) messaging system. Design to use with Dart and flutter.

## Dart Examples:

Run the `example/main.dart`:

```
dart example/main.dart
```

### Simple poll example

```dart
import 'package:dart_nats_client/dart_nats_client.dart';

void main() async {
  // Create client instance
  var client = Client();
  // Connect to server
  await client.connect('localhost');
  // Subscribe on topic
  var sub = client.sub('subject1');
  // Publish string to topic
  client.pubString('subject1', 'message1');
  // Wait message from topic
  var msg = await sub.poll();
  // Print received message
  print(msg.string);
  // Unsubscribe from topic
  sub.unSub();
  // Close client connection
  client.close();
}
```

### Listener example

```dart
import 'package:dart_nats_client/dart_nats_client.dart';

void main() async {
  // Create client instance
  var client = Client();
  // Connect to server
  await client.connect('localhost');
  // Subscribe on topic
  var sub = client.getStream().listen((msg) {
      print(msg.string);
    });
  // Publish string to topic
  client.pubString('subject1', 'message1');
  // Some delay for receiving
  await Future.delayed(Duration(milliseconds: 100));
  // Unsubscribe from topic
  sub.unSub();
  // Close client connection
  client.close();
}
```

## Flutter Examples

Import and Declare object
```dart
import 'package:dart_nats_client/dart_nats_client.dart' as nats;

  nats.Client natsClient;
  nats.Subscription fooSub, barSub;
```

Simply connect to server and subscribe to subject
```dart
  void connect() {
    natsClient = nats.Client();
    natsClient.connect('demo.nats.io');
    fooSub = natsClient.sub('foo');
    barSub = natsClient.sub('bar');
  }
```
Use as Stream in StreamBuilder
```dart
          StreamBuilder(
            stream: fooSub.stream,
            builder: (context, AsyncSnapshot<nats.Message> snapshot) {
              return Text(snapshot.hasData ? '${snapshot.data.string}' : '');
            },
          ),
```

Publish Message
```dart
      natsClient.pubString('subject','message string');
```

Dispose 
```dart
  void dispose() {
    natsClient.close();
    super.dispose();
  }
```

Full Flutter sample code [example/flutter/main.dart](https://github.com/chartchuo/dart-nats/blob/master/example/flutter/main_dart)

### App permissions

#### Android permissions

For android you need to add to `android/app/src/profile/AndroidManifest` file lines:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

For activiy in backgroud:

```xml
<!-- Allows run app in background -->
<uses-permission android:name="android.permission.REQUEST_COMPANION_RUN_IN_BACKGROUND"/>
<!-- Allows app use data in background -->
<uses-permission android:name="android.permission.REQUEST_COMPANION_USE_DATA_IN_BACKGROUND"/>
```

#### iOS permissions

For iOS you don't need any specific permissions for NATS client.

But for background activity you need to add to file `ios/Runner/Info.plist` lines:


```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>external-accessory</string>
  <string>fetch</string>
  <string>processing</string>
  <string>remote-notification</string>
</array>
```

## Testing

For running unit-tests use `pub run test test/` in project root folder.

NOTE. For testing you need run NATS in docker. [Instruction](https://docs.nats.io/nats-server/nats_docker)

## Features

The following is a list of features currently supported and planned by this client:

* [x] - Publish
* [x] - Subscribe, unsubscribe
* [x] - NUID, Inbox
* [x] - Reconnect to single server when connection lost and resume subscription
* [x] - Unsubscribe after N message
* [x] - Request, Respond
* [ ] - Respond, Request example
* [x] - Queue subscribe
* [ ] - caches, flush, drain
* [ ] - Request timeout
* [ ] - structured data
* [ ] - Connection option (cluster, timeout,ping interval, max ping, echo,... )
* [ ] - Random automatic reconnection, disable reconnect, number of attempts, pausing
* [ ] - Connect to cluster,randomize, Automatic reconnect upon connection failure base server info
* [ ] - Events/status disconnect handler, reconnect handler
* [ ] - Buffering message during reconnect atempts
* [ ] - All authentication models, including NATS 2.0 JWT and seed keys
* [ ] - TLS support
