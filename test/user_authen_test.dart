import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'package:test/test.dart';
import 'package:dart_nats_client/dart_nats_client.dart';

// start nats server using
// nats-server -DV -m 8222 -user foo -pass bar

void main() {
  group('all', () {
    test('await', () async {
      // Generate random subject
      String subject = Uuid().v4();

      var client = Client();
      await client.connect('localhost',
          connectOption: ConnectOption(user: 'foo', pass: 'bar'));
      var sub = client.sub(subject);
      var result = client.pub(subject, Uint8List.fromList('message1'.codeUnits),
          buffer: false);
      expect(result, true);

      var msg = await sub.poll();
      client.close();
      expect(String.fromCharCodes(msg.data), equals('message1'));
    });
  });
}
