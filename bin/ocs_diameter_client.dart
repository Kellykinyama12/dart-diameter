import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  final List<AVP> avps;

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
    final buffer = BytesBuilder();
    buffer.addByte(version);
    int flags = (request ? 0x80 : 0) | (proxyable ? 0x40 : 0) | (error ? 0x20 : 0) | (retransmitted ? 0x10 : 0);
    buffer.addByte(flags);
    buffer.addByte(commandCode >> 16);
    buffer.addByte((commandCode >> 8) & 0xFF);
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
    for (var avp in avps) {
      buffer.add(avp.encode());
    }
    return buffer.toBytes();
  }
}

class AVP {
  final int code;
  final bool mandatory;
  final bool protected;
  final Uint8List value;

  AVP({
    required this.code,
    required this.mandatory,
    required this.protected,
    required this.value,
  });

  List<int> encode() {
    final buffer = BytesBuilder();
    buffer.addByte(code >> 24);
    buffer.addByte((code >> 16) & 0xFF);
    buffer.addByte((code >> 8) & 0xFF);
    buffer.addByte(code & 0xFF);
    int flags = (mandatory ? 0x40 : 0) | (protected ? 0x20 : 0);
    buffer.addByte(flags);
    buffer.addByte(0); // Reserved byte
    buffer.addByte(0); // Length placeholder
    buffer.addByte(0); // Length placeholder
    buffer.add(value);
    // Update the length field
    int length = 8 + value.length;
    buffer.toBytes()[6] = length >> 8;
    buffer.toBytes()[7] = length & 0xFF;
    return buffer.toBytes();
  }
}

Future<void> sendCreditControlRequest() async {
  final socket = await Socket.connect('diameter-server.example.com', 3868);

  final avps = [
    AVP(
      code: 263, // Session-Id AVP code
      mandatory: true,
      protected: false,
      value: utf8.encode('session-id-1234') as Uint8List,
    ),
    AVP(
      code: 416, // CC-Request-Type AVP code
      mandatory: true,
      protected: false,
      value: Uint8List.fromList([1]), // Initial request
    ),
    AVP(
      code: 415, // CC-Request-Number AVP code
      mandatory: true,
      protected: false,
      value: Uint8List.fromList([0, 0, 0, 1]), // Request number 1
    ),
    AVP(
      code: 8, // User-Name AVP code
      mandatory: true,
      protected: false,
      value: utf8.encode('user@example.com') as Uint8List,
    ),
  ];

  final message = DiameterMessage(
    version: 1,
    request: true,
    proxyable: true,
    error: false,
    retransmitted: false,
    commandCode: 272, // Credit-Control-Request
    applicationId: 4, // Diameter Credit Control Application
    hopByHopId: 0x12345678,
    endToEndId: 0x9abcdef0,
    avps: avps,
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
  sendCreditControlRequest();
}
