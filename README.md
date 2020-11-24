# Dart NATS Client

A Dart client for the [NATS](https://nats.io) messaging system. Design to use with Dart and flutter.

## Dart Examples

All examples can be found in `example` folder.

### Simple poll example

Run with:

```sh
dart example/simple_sub_pub.dart
```

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

Run with:

```sh
dart example/simple_listener.dart
```

```dart
import 'package:dart_nats_client/dart_nats_client.dart';

void main() async {
  // Create client instance
  var client = Client();
  // Connect to server
  await client.connect('localhost');
  // Subscribe on topic
  var sub = client.sub('subject1');
  // Subscribe on topic
  var subListener = sub.getStream().listen((msg) {
    print(msg.string);
  });
  // Publish string to topic
  client.pubString('subject1', 'message1');
  // Some delay for receiving
  await Future.delayed(Duration(milliseconds: 100));
  // Cancel listener
  await subListener.cancel();
  // Unsubscribe from topic
  sub.unSub();
  // Close client connection
  client.close();
}
```

### Flutter Example

Run with:

```sh
cd example/flutter
flutter run
```

Full Flutter sample code in `example/flutter/main.dart`

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
