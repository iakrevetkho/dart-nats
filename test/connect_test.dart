import 'dart:typed_data';

import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:dart_nats_client/dart_nats_client.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('all', () {
    test('unwaited', () async {
      // Generate random subject
      String subject = Uuid().v4();

      var client = Client();
      unawaited(client.connect('localhost', retryInterval: 1));

      // Publish should send exception
      try {
        client.pub(subject, Uint8List.fromList('message1'.codeUnits));
      } catch (ex) {
        expect(ex, TypeMatcher<Exception>());
      }
      // Sibscription should send exception
      try {
        client.sub(subject);
      } catch (ex) {
        expect(ex, TypeMatcher<Exception>());
      }
    });
    test('await', () async {
      // Generate random subject
      String subject = Uuid().v4();

      var client = Client();
      await client.connect('localhost');
      var sub = client.sub(subject);
      var result = client.pub(subject, Uint8List.fromList('message1'.codeUnits),
          buffer: false);
      expect(result, true);

      var msg = await sub.poll();
      client.close();
      expect(String.fromCharCodes(msg.data), equals('message1'));
    });
    test('retry failed', () async {
      var client = Client();
      bool errorCaught = false;
      // Await connection
      await client
          .connect('blabla', retriesCount: 3, retryInterval: 1)
          .catchError((Object error) {
        errorCaught = true;
      });
      // Expect error
      expect(errorCaught, true);
    });
  });
}
