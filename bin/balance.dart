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

  static DiameterMessage decode(List<int> data) {
    final buffer = Uint8List.fromList(data);
    final byteData = ByteData.view(buffer.buffer);
    int version = byteData.getUint8(0);
    int flags = byteData.getUint8(1);
    bool request = (flags & 0x80) != 0;
    bool proxyable = (flags & 0x40) != 0;
    bool error = (flags & 0x20) != 0;
    bool retransmitted = (flags & 0x10) != 0;
    int commandCode = byteData.getUint24(2);
    int applicationId = byteData.getUint32(5);
    int hopByHopId = byteData.getUint32(9);
    int endToEndId = byteData.getUint32(13);

    int offset = 17;
    List<AVP> avps = [];
    while (offset < data.length) {
      AVP avp = AVP.decode(buffer.sublist(offset));
      avps.add(avp);
      offset += avp.length;
    }

    return DiameterMessage(
      version: version,
      request: request,
      proxyable: proxyable,
      error: error,
      retransmitted: retransmitted,
      commandCode: commandCode,
      applicationId: applicationId,
      hopByHopId: hopByHopId,
      endToEndId: endToEndId,
      avps: avps,
    );
  }
}

class AVP {
  final int code;
  final bool mandatory;
  final bool protected;
  final Uint8List value;
  final int length;

  AVP({
    required this.code,
    required this.mandatory,
    required this.protected,
    required this.value,
  }) : length = 8 + value.length;

  List<int> encode() {
    final buffer = BytesBuilder();
    buffer.addByte(code >> 24);
    buffer.addByte((code >> 16) & 0xFF);
    buffer.addByte((code >> 8) & 0xFF);
    buffer.addByte(code & 0xFF);
    int flags = (mandatory ? 0x40 : 0) | (protected ? 0x20 : 0);
    buffer.addByte(flags);
    buffer.addByte(0); // Reserved byte
    buffer.addByte(length >> 8);
    buffer.addByte(length & 0xFF);
    buffer.add(value);
    return buffer.toBytes();
  }

  static AVP decode(List<int> data) {
    final buffer = Uint8List.fromList(data);
    final byteData = ByteData.view(buffer.buffer);
    int code = byteData.getUint32(0);
    int flags = byteData.getUint8(4);
    bool mandatory = (flags & 0x40) != 0;
    bool protected = (flags & 0x20) != 0;
    int length = byteData.getUint16(6);
    Uint8List value = buffer.sublist(8, length);
    return AVP(
      code: code,
      mandatory: mandatory,
      protected: protected,
      value: value,
    );
  }
}

extension ByteDataExtensions on ByteData {
  int getUint24(int byteOffset, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (getUint8(byteOffset) << 16) |
             (getUint8(byteOffset + 1) << 8) |
             getUint8(byteOffset + 2);
    } else {
      return (getUint8(byteOffset + 2) << 16) |
             (getUint8(byteOffset + 1) << 8) |
             getUint8(byteOffset);
    }
  }
}

// Simple in-memory database to track client data usage
class InMemoryDatabase {
  final Map<String, int> _dataUsage = {};

  int getUsage(String sessionId) {
    return _dataUsage[sessionId] ?? 0;
  }

  void addUsage(String sessionId, int bytes) {
    _dataUsage[sessionId] = getUsage(sessionId) + bytes;
  }
}

final InMemoryDatabase database = InMemoryDatabase();

void handleRequest(Socket socket) {
  socket.listen((data) {
    DiameterMessage request = DiameterMessage.decode(data);
    String sessionId = utf8.decode(request.avps.firstWhere((avp) => avp.code == 263).value);
    int usedServiceUnit = ByteData.sublistView(request.avps.firstWhere((avp) => avp.code == 446).value).getUint32(0);

    print('Received CCR for Session-Id: $sessionId with Used-Service-Unit: $usedServiceUnit bytes');

    // Update the data usage in the database
    database.addUsage(sessionId, usedServiceUnit);

    // Prepare the response
    int grantedServiceUnit = 1024 * 1024; // 1 MB granted for simplicity
    final responseAvps = [
      AVP(
        code: 263, // Session-Id AVP code
        mandatory: true,
        protected: false,
        value: request.avps.firstWhere((avp) => avp.code == 263).value,
      ),
      AVP(
        code: 268, // Result-Code AVP code
        mandatory: true,
        protected: false,
        value: Uint8List.fromList([0, 0, 0, 2001]), // Success
      ),
      AVP(
        code: 421, // Granted-Service-Unit AVP code
        mandatory: true,
        protected: false,
        value: Uint8List(4)..buffer.asByteData().setUint32(0, grantedServiceUnit),
      ),
    ];

    DiameterMessage response = DiameterMessage(
      version: 1,
      request: false,
      proxyable: false,
      error: false,
      retransmitted: false,
      commandCode: request.commandCode,
      applicationId: request.applicationId,
      hopByHopId: request.hopByHopId,
      endToEndId: request.endToEndId,
      avps: responseAvps,
    );

    socket.add(response.encode());
    socket.flush();
  }, onDone: () {
    socket.destroy();
  });
}

Future<void> startDiameterServer() async {
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 3868);
  print('Diameter server listening on port 3868');
  await for (Socket socket in server) {
    handleRequest(socket);
  }
}

void main() {
  startDiameterServer();
}
