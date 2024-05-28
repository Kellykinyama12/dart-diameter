import 'dart:convert';
import 'dart:io';

class DiameterMessage {
  final int version;
  final bool request;
  final bool proxyable;
  final bool error;
  final bool retransmitted;
  final int commandCode;
  final int applicationId;
  final int hopByHopId;
  final int endToEndId;
  final List<int> avps;

  DiameterMessage({
    required this.version,
    required this.request,
    required this.proxyable,
    required this.error,
    required this.retransmitted,
    required this.commandCode,
    required this.applicationId,
    required this.hopByHopId,
    required this.endToEndId,
    required this.avps,
  });

  List<int> encode() {
    // Simplified encoding logic for illustration
    final buffer = BytesBuilder();
    buffer.addByte(version);
    buffer.addByte((request ? 0x80 : 0) | (proxyable ? 0x40 : 0) | (error ? 0x20 : 0) | (retransmitted ? 0x10 : 0));
    buffer.addByte(commandCode >> 16);
    buffer.addByte(commandCode & 0xFF);
    buffer.addByte(applicationId >> 24);
    buffer.addByte((applicationId >> 16) & 0xFF);
    buffer.addByte((applicationId >> 8) & 0xFF);
    buffer.addByte(applicationId & 0xFF);
    buffer.addByte(hopByHopId >> 24);
    buffer.addByte((hopByHopId >> 16) & 0xFF);
    buffer.addByte((hopByHopId >> 8) & 0xFF);
    buffer.addByte(hopByHopId & 0xFF);
    buffer.addByte(endToEndId >> 24);
    buffer.addByte((endToEndId >> 16) & 0xFF);
    buffer.addByte((endToEndId >> 8) & 0xFF);
    buffer.addByte(endToEndId & 0xFF);
    buffer.add(avps);
    return buffer.toBytes();
  }
}

Future<void> sendDiameterRequest() async {
  final socket = await Socket.connect('diameter-server.example.com', 3868);

  final message = DiameterMessage(
    version: 1,
    request: true,
    proxyable: true,
    error: false,
    retransmitted: false,
    commandCode: 257, // Example command code
    applicationId: 0, // Base protocol
    hopByHopId: 0x12345678, // Example hop-by-hop ID
    endToEndId: 0x9abcdef0, // Example end-to-end ID
    avps: utf8.encode('Example AVP Data'), // Simplified AVP encoding
  );

  socket.add(message.encode());
  await socket.flush();
  socket.listen((data) {
    print('Received data: ${utf8.decode(data)}');
  }, onDone: () {
    print('Connection closed');
    socket.destroy();
  }, onError: (error) {
    print('Error: $error');
    socket.destroy();
  });
}

void main() {
  sendDiameterRequest();
}
