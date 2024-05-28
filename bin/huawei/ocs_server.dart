import 'dart:convert';
import 'dart:typed_data';
import 'ptn_device.dart';

class OcsServer {
  List<int> processCCR(List<int> data) {
    Map<String, dynamic> request = jsonDecode(utf8.decode(data));
    print('Received CCR from PTN Device:');
    print('Session ID: ${request['sessionId']}');
    print('Requested Data: ${request['requestedData']}');

    // Process CCR and generate CCA response
    String sessionId = request['sessionId'];
    int grantedData = 1024; // Simulated granted data in bytes
    int resultCode = 2001; // Success
    Map<String, dynamic> response = {
      'sessionId': sessionId,
      'grantedData': grantedData,
      'resultCode': resultCode,
    };
    return utf8.encode(jsonEncode(response));
  }
}
void main() {
  // Simulate PTN device sending CCR to OCS server
  PTNDevice ptnDevice = PTNDevice(sessionId: 'session123', requestedData: 2048);
  List<int> ccrMessage = ptnDevice.sendCCR();

  // Simulate OCS server processing CCR and sending CCA back to PTN device
  OcsServer ocsServer = OcsServer();
  List<int> ccaMessage = ocsServer.processCCR(ccrMessage);

  // PTN device receives CCA from OCS server
  ptnDevice.receiveCCA(ccaMessage);
}
