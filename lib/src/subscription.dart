/// External packages
import 'dart:async';

/// Internal packages

/// Local packages
import 'client.dart';
import 'message.dart';

/// subscription class
class Subscription {
  ///subscriber id (audo generate)
  final int sid;

  ///subject and queuegroup of this subscription
  final String subject, queueGroup;

  final Client _client;

  final _controller = StreamController<Message>();

  /// Stream of messages from subsription
  Stream<Message> _stream;

  ///constructure
  Subscription(this.sid, this.subject, this._client, {this.queueGroup}) {
    _stream = _controller.stream.asBroadcastStream();
  }

  /// Get subscription stream object
  Stream<Message> getStream() {
    return _stream;
  }

  /// Unsubscribe frrom subject
  void unSub() {
    _client.unSub(this);
  }

  /// Poll message from server
  Future<Message> poll() {
    return _stream.first;
  }

  ///sink messat to listener
  void add(Message msg) {
    _controller.sink.add(msg);
  }

  ///close the stream
  void close() {
    _controller.close();
  }
}
