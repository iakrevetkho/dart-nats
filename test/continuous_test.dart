@Timeout(Duration(seconds: 60))

/// External packages
import 'dart:isolate';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// Internal packages
import 'package:dart_nats_client/dart_nats_client.dart';

/// Local packages

// Number of itterations
const iteration = 10000;

void run(List<Object> arguments) async {
  // Get send port from arguments
  SendPort sendPort = arguments[0];
  // Get subject from arguments
  String subject = arguments[1];

  var client = Client();
  await client.connect('localhost');
  for (var i = 0; i < iteration; i++) {
    client.pubString(subject, i.toString());
    //commend out for reproduce issue#4
    await Future.delayed(Duration(milliseconds: 1));
  }
  await client.ping();
  client.close();
  sendPort.send('finish');
}

void main() {
  group('all', () {
    test('continuous', () async {
      // Generate random subject
      var subject = Uuid().v4();

      var client = Client();
      await client.connect('localhost');
      var sub = client.sub(subject);
      var r = 0;

      sub.getStream().listen((msg) {
        r++;
      });

      var receivePort = ReceivePort();
      var iso = await Isolate.spawn(run, [receivePort.sendPort, subject]);
      await receivePort.first;
      iso.kill();
      //wait for last message send round trip to server
      await Future.delayed(Duration(seconds: 1));

      sub.close();
      client.close();

      expect(r, equals(iteration));
    });
  });
}
