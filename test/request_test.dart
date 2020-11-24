import 'dart:typed_data';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:dart_nats_client/dart_nats_client.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('all', () {
    test('simple', () async {
      // Generate random subject
      String subject = Uuid().v4();

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
      String subject = Uuid().v4();

      var server = Client();
      await server.connect('localhost');
      var service = server.sub(subject);
      service.getStream().listen((m) {
        m.respondString('respond');
      });

      var requester = Client();
      await requester.connect('localhost');
      var inbox = newInbox();
      // Subscribe on inbox
      var inboxSub = requester.sub(inbox);
      // Send request
      requester.pubString(subject, 'request', replyTo: inbox);

      var receive = await inboxSub.poll();

      // Terminate
      server.close();
      requester.close();
      expect(receive.string, equals('respond'));
    });
    test('resquest', () async {
      // Generate random subject
      String subject = Uuid().v4();

      var server = Client();
      await server.connect('localhost');
      var service = server.sub(subject);
      unawaited(service.poll().then((m) {
        m.respond(Uint8List.fromList('respond'.codeUnits));
      }));

      var client = Client();
      await client.connect('localhost');
      var receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));

      // Terminate
      server.close();
      client.close();
      expect(receive.string, equals('respond'));
    });
    test('repeat resquest', () async {
      // Generate random subject
      String subject = Uuid().v4();

      var server = Client();
      await server.connect('localhost');
      var service = server.sub(subject);
      service.getStream().listen((m) {
        m.respond(Uint8List.fromList('respond'.codeUnits));
      });

      var client = Client();
      await client.connect('localhost');
      var receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));
      receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));
      receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));
      receive = await client.request(
          subject, Uint8List.fromList('request'.codeUnits));

      // Terminate
      server.close();
      client.close();
      expect(receive.string, equals('respond'));
    });
  });
}
