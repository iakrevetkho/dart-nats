import 'dart:async';
import 'dart:convert';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'package:dart_nats_client/dart_nats_client.dart';
import 'package:logger/logger.dart';

import 'common.dart';
import 'message.dart';
import 'subscription.dart';

enum _ReceiveState {
  idle, //op=msg -> msg
  msg, //newline -> idle

}

///status of the nats client
enum Status {
  /// discontected or not connected
  disconnected,

  ///connected to server
  connected,

  ///alread close by close or server
  closed,

  ///automatic reconnection to server
  reconnecting,

  ///connecting by connect() method
  connecting,

  // draining_subs,
  // draining_pubs,
}

class _Pub {
  /// Subject of publication
  final String subject;

  /// Data array
  final List<int> data;

  /// Name of user if it is reply
  final String replyTo;

  _Pub(this.subject, this.data, this.replyTo);
}

/// NATS client
class Client {
  /// Host name
  String _host;

  /// NATS port
  int _port;

  /// Socket connection object
  Socket _socket;

  /// Connection info
  Info _info;

  /// Ping controller
  Completer _pingCompleter;

  /// Connection controller
  Completer _connectCompleter;

  /// Status of the client
  Status status;

  /// Connection options
  var _connectOption = ConnectOption(verbose: false);

  ///server info
  Info get info => _info;

  /// Subscriptions map
  final _subs = <int, Subscription>{};

  /// Subscription backend
  final _backendSubs = <int, bool>{};

  /// Publication buffer
  final _pubBuffer = <_Pub>[];

  /// Instance ID
  int _ssid = 0;

  /// Buffer for operations
  List<int> _operationsBuffer = [];

  /// Logger instance
  Logger _logger;

  /// Default constructor
  Client({Logger logger}) : _logger = logger {
    // Check logger or init new
    if (_logger == null) {
      _logger = Logger(level: Level.info);
    }
    // Set status default disconnected
    status = Status.disconnected;
  }

  /// Connect to NATS server
  Future connect(String host,
      {int port = 4222,
      ConnectOption connectOption,
      int timeout = 5,
      int retriesCount = 5,
      int retryInterval = 10}) async {
    // Init connection controller
    _connectCompleter = Completer();
    // Check  connection status. If connected, don't allow connect again
    if (status != Status.disconnected && status != Status.closed) {
      // Return Future error for await catch
      return Future.error('Error: status not disconnected and not closed');
    }
    // Save hostname
    _host = host;
    // Save port name
    _port = port;
    // Check connection options validity and save
    if (connectOption != null) _connectOption = connectOption;
    // Declare last connection exception for catch exception throw retry connect
    Exception lastException;

    // Start for loop for cennection with retries
    _logger.d("Start connecting loop with $retriesCount retries count");
    for (var i = 0; i < retriesCount; i++) {
      _logger.d("Connect retry #$i/$retriesCount for connect to $host:$port");
      if (i == 0) {
        // If first attempt, status - connecting
        status = Status.connecting;
        _logger.d("Connect Status = $status");
      } else {
        // If not first attempt, set status reconnecting
        status = Status.reconnecting;
        _logger.d("Connect Status = $status");
        // Add delay on retryInterval for next attempt
        await Future.delayed(Duration(seconds: retryInterval));
      }

      // Try-Catch socket exceptions
      try {
        // Init socket connection.
        // On this stage exception can be caught.
        _socket = await Socket.connect(_host, _port,
            timeout: Duration(seconds: timeout));
        // Set status connected after socket was inited
        status = Status.connected;
        _logger.d("Connect Status = $status");
        // Set complete status to connect controller
        _connectCompleter.complete();
        // Add connecton options
        _addConnectOption(_connectOption);
        // Clear backend subscriptions
        _backendSubscriptAll();
        // Clear publications buffer
        _flushPubBuffer();
        // Clear buffer
        _operationsBuffer = [];
        // Start lister socket
        _socket.listen((d) {
          _operationsBuffer.addAll(d);
          while (_receiveState == _ReceiveState.idle &&
              _operationsBuffer.contains(13)) {
            _processOp();
          }
        }, onDone: () {
          // On socket close action
          _logger.d("Socket onDone event");
          status = Status.disconnected;
          _logger.d("Connect Status = $status");
          _socket.close();
        }, onError: (err) {
          // On socket error
          _logger.e("Socket onError event: $err");
          status = Status.disconnected;
          _logger.d("Connect Status = $status");
          _socket.close();
        });
        // Exit from retry loop on success
        break;
      }
      // Catch socket exceptions
      on SocketException catch (ex) {
        _logger.e("On connection catched socket exception: $ex");
        // Close connection
        close();
        // Save last exception
        lastException = ex;
      }
    }
    // If connection not success, save error
    if (status != Status.connected) {
      // Set error into Completer
      _logger.e("After all attempts socket is not connected. "
          "lastException: $lastException");
      _connectCompleter.completeError(lastException);
    } else {
      _logger.i("Connected to '$host:$port'");
    }

    return _connectCompleter.future;
  }

  void _backendSubscriptAll() {
    _backendSubs.clear();
    _subs.forEach((sid, s) async {
      _sub(s.subject, sid, queueGroup: s.queueGroup);
      // s.backendSubscription = true;
      _backendSubs[sid] = true;
    });
  }

  void _flushPubBuffer() {
    _pubBuffer.forEach((p) {
      _pub(p);
    });
  }

  _ReceiveState _receiveState = _ReceiveState.idle;
  String _receiveLine1 = '';
  void _processOp() async {
    ///find endline
    var nextLineIndex = _operationsBuffer.indexWhere((c) {
      if (c == 13) {
        return true;
      }
      return false;
    });
    if (nextLineIndex == -1) return;
    var line = String.fromCharCodes(
        _operationsBuffer.sublist(0, nextLineIndex)); // retest
    if (_operationsBuffer.length > nextLineIndex + 2) {
      _operationsBuffer.removeRange(0, nextLineIndex + 2);
    } else {
      _operationsBuffer = [];
    }

    ///decode operation
    var i = line.indexOf(' ');
    String op, data;
    if (i != -1) {
      op = line.substring(0, i).trim().toLowerCase();
      data = line.substring(i).trim();
    } else {
      op = line.trim().toLowerCase();
      data = '';
    }

    ///process operation
    switch (op) {
      case 'msg':
        _receiveState = _ReceiveState.msg;
        _receiveLine1 = line;
        _processMsg();
        break;
      case 'info':
        _info = Info.fromJson(jsonDecode(data));
        break;
      case 'ping':
        _add('pong');
        break;
      case '-err':
        _processErr(data);
        break;
      case 'pong':
        _pingCompleter.complete();
        break;
      case '+ok':
        //do nothing
        break;
    }
  }

  void _processErr(String data) {
    close();
  }

  void _processMsg() {
    var s = _receiveLine1.split(' ');
    var subject = s[1];
    var sid = int.parse(s[2]);
    String replyTo;
    int length;
    if (s.length == 4) {
      length = int.parse(s[3]);
    } else {
      replyTo = s[3];
      length = int.parse(s[4]);
    }
    if (_operationsBuffer.length < length) return;
    var payload = Uint8List.fromList(_operationsBuffer.sublist(0, length));
    // _operationsBuffer = _operationsBuffer.sublist(length + 2);
    if (_operationsBuffer.length > length + 2) {
      _operationsBuffer.removeRange(0, length + 2);
    } else {
      _operationsBuffer = [];
    }

    if (_subs[sid] != null) {
      _subs[sid].add(Message(subject, sid, payload, this, replyTo: replyTo));
    }
    _receiveLine1 = '';
    _receiveState = _ReceiveState.idle;
  }

  /// get server max payload
  int maxPayload() => _info?.maxPayload;

  ///ping server current not implement pong verification
  Future ping() {
    _pingCompleter = Completer();
    _add('ping');
    return _pingCompleter.future;
  }

  void _addConnectOption(ConnectOption c) {
    _add('connect ' + jsonEncode(c.toJson()));
  }

  ///default buffer action for pub
  var defaultPubBuffer = true;

  ///publish by byte (Uint8List) return true if sucess sending or buffering
  ///return false if not connect
  bool pub(String subject, Uint8List data, {String replyTo, bool buffer}) {
    _logger.d(
        "Publish data '$data' to subject '$subject' with reply to '$replyTo'");
    buffer ??= defaultPubBuffer;
    if (status != Status.connected) {
      if (buffer) {
        _pubBuffer.add(_Pub(subject, data, replyTo));
      } else {
        return false;
      }
    }

    if (replyTo == null) {
      _add('pub $subject ${data.length}');
    } else {
      _add('pub $subject $replyTo ${data.length}');
    }
    _addByte(data);

    return true;
  }

  ///publish by string
  bool pubString(String subject, String str,
      {String replyTo, bool buffer = true}) {
    return pub(subject, utf8.encode(str), replyTo: replyTo, buffer: buffer);
  }

  bool _pub(_Pub p) {
    if (p.replyTo == null) {
      _add('pub ${p.subject} ${p.data.length}');
    } else {
      _add('pub ${p.subject} ${p.replyTo} ${p.data.length}');
    }
    _addByte(p.data);

    return true;
  }

  ///subscribe to subject option with queuegroup
  Subscription sub(String subject, {String queueGroup}) {
    _logger.d("Create subsription on '$subject'");
    _ssid++;
    var s = Subscription(_ssid, subject, this, queueGroup: queueGroup);
    _subs[_ssid] = s;
    if (status == Status.connected) {
      _sub(subject, _ssid, queueGroup: queueGroup);
      _backendSubs[_ssid] = true;
    }
    return s;
  }

  void _sub(String subject, int sid, {String queueGroup}) {
    if (queueGroup == null) {
      _add('sub $subject $sid');
    } else {
      _add('sub $subject $queueGroup $sid');
    }
  }

  ///unsubscribe
  bool unSub(Subscription s) {
    _logger.d("Unsubscribe from '$s.subject'");
    var sid = s.sid;

    if (_subs[sid] == null) return false;
    _unSub(sid);
    _subs.remove(sid);
    s.close();
    _backendSubs.remove(sid);
    return true;
  }

  ///unsubscribe by id
  bool unSubById(int sid) {
    if (_subs[sid] == null) return false;
    return unSub(_subs[sid]);
  }

  //todo unsub with max msgs

  void _unSub(int sid, {String maxMsgs}) {
    if (maxMsgs == null) {
      _add('unsub $sid');
    } else {
      _add('unsub $sid $maxMsgs');
    }
  }

  // Send data to stream or throw exception if stream in null
  void _add(String str) {
    if (_socket == null)
      throw new Exception("Can't perform _add function. Socket is closed.");
    // Add data to socket
    _socket.add(utf8.encode(str + '\r\n'));
  }

  // Send bytes data to stream or throw exception if stream in null
  void _addByte(List<int> msg) {
    if (_socket == null)
      throw new Exception("Can't perform _add function. Socket is closed.");
    // Add data
    _socket.add(msg);
    // Add end of line
    _socket.add(utf8.encode('\r\n'));
  }

  final _inboxs = <String, Subscription>{};

  /// Request will send a request payload and deliver the response message,
  /// or an error, including a timeout if no message was received properly.
  Future<Message> request(String subject, Uint8List data,
      {String queueGroup, Duration timeout}) {
    _logger.d("Send request into subject '$subject' "
        "to queue group '$queueGroup' "
        " with data '$data'"
        " and timeout $timeout");
    timeout ??= Duration(seconds: 2);
    data ??= Uint8List(0);

    if (_inboxs[subject] == null) {
      var inbox = newInbox();
      _inboxs[subject] = sub(inbox, queueGroup: queueGroup);
    }

    // TODO timeout
    // TODO refactor
    var stream = _inboxs[subject].getStream();
    var respond = stream.take(1).single;
    // Publish reply
    pub(subject, data, replyTo: _inboxs[subject].subject);

    return respond;
  }

  /// requestString() helper to request()
  Future<Message> requestString(String subject, String data,
      {String queueGroup, Duration timeout}) {
    data ??= '';
    return request(subject, Uint8List.fromList(data.codeUnits),
        queueGroup: queueGroup, timeout: timeout);
  }

  /// Close connection to NATS server unsub to server
  void close() {
    _logger.i("Close connection to '$_host:$_port'");
    // Clear backend subscriptions
    _backendSubscriptAll();

    _inboxs.clear();
    _socket?.close();
    status = Status.closed;
  }
}
