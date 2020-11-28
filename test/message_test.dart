/// External packages
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

/// Internal packages
import 'package:dart_nats_client/dart_nats_client.dart';

/// Local packages

String _getRandString(int len) {
  var random = Random.secure();
  var values = List<int>.generate(len, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

void main() {
  group('all', () {
    test('simple', () async {
      // Generate random subject
      var subject = Uuid().v4();

      var client = Client();
      await client.connect('localhost', retryInterval: 1);
      var sub = client.sub(subject);
      client.pub(subject, Uint8List.fromList('message1'.codeUnits));
      var msg = await sub.poll();

      // Terminate
      client.close();
      expect(String.fromCharCodes(msg.data), equals('message1'));
    });
    test('respond', () async {
      // Generate random subject
      var subject = Uuid().v4();

      var server = Client();
      await server.connect('localhost');

      var service = server.sub(subject);

      service.getStream().listen((m) {
        m.respondString('respond');
      });

      var requester = Client();
      await requester.connect('localhost');
      var inbox = newInbox();
      var inboxSub = requester.sub(inbox);

      requester.pubString(subject, 'request', replyTo: inbox);

      var receive = await inboxSub.poll();

      // Terminate
      server.close();
      requester.close();
      expect(receive.string, equals('respond'));
    });
    test('resquest', () async {
      // Generate random subject
      var subject = Uuid().v4();

      var server = Client();
      await server.connect('localhost');
      var service = server.sub(subject);
      service.getStream().listen((m) {
        m.respondString('respond');
      });

      var client = Client();
      await client.connect('localhost');
      var receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));

      server.close();
      service.close();
      expect(receive.string, equals('respond'));
    });
    test('long message', () async {
      // Generate random subject
      var subject = Uuid().v4();

      // Generate text
      var txt = _getRandString(256);
      var client = Client();
      await client.connect('localhost', retryInterval: 1);
      var sub = client.sub(subject);
      client.pub(subject, Uint8List.fromList(txt.codeUnits));
      client.pub(subject, Uint8List.fromList(txt.codeUnits));
      var msg = await sub.poll();
      print(msg.data);
      msg = await sub.poll();
      print(msg.data);

      // Terminate
      client.close();
      expect(String.fromCharCodes(msg.data), equals(txt));
    });
  });
}
