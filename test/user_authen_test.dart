/// External packages
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

/// Internal packages
import 'package:dart_nats_client/dart_nats_client.dart';

/// Local packages

void main() {
  group('all', () {
    test('await', () async {
      // Generate random subject
      var subject = Uuid().v4();

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
