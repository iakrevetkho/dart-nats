import 'package:dart_nats_client/dart_nats_client.dart';

void main() {
  // Run Subscribe-Publish example
  subPubExample();

  // Run Listener example
  listenerExample();
}

void subPubExample() async {
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

void listenerExample() async {
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
