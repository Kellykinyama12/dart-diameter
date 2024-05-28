import 'dart:convert';
import 'dart:typed_data';

class PTNDevice {
  String sessionId;
  int requestedData;

  PTNDevice({required this.sessionId, required this.requestedData});

  List<int> sendCCR() {
    Map<String, dynamic> message = {
      'sessionId': sessionId,
      'requestedData': requestedData,
    };
    return utf8.encode(jsonEncode(message));
  }

  void receiveCCA(List<int> data) {
    Map<String, dynamic> response = jsonDecode(utf8.decode(data));
    print('Received CCA from OCS Server:');
    print('Session ID: ${response['sessionId']}');
    print('Granted Data: ${response['grantedData']}');
    print('Result Code: ${response['resultCode']}');
  }
}
