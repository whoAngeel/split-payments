import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WsService {
  WebSocketChannel? _channel;

  void connect(
    String sessionId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.13:4001/ws/$sessionId'),
    );

    _channel!.stream.listen(
      (data) => onMessage(jsonDecode(data as String) as Map<String, dynamic>),
      onError: (_) {},
      onDone: () {},
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
