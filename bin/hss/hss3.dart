import 'dart:convert';
import 'dart:io';

// Subscriber class to hold subscriber information
class Subscriber {
  final String imsi;
  final String msisdn;
  final String authenticationKey;

  Subscriber(
      {required this.imsi,
      required this.msisdn,
      required this.authenticationKey});
}

// Home Subscriber Server class
class HssServer {
  final Map<String, Subscriber> _subscribers = {
    '123456789012345': Subscriber(
        imsi: '123456789012345',
        msisdn: '+1234567890',
        authenticationKey: 'abcdef123456'),
    '987654321098765': Subscriber(
        imsi: '987654321098765',
        msisdn: '+9876543210',
        authenticationKey: '654321abcdef'),
  };

  // Method to handle Authentication-Information-Request (AIR) messages
  void handleAirRequest(Socket socket, List<int> request) {
    String imsi = utf8.decode(request);
    Subscriber? subscriber = _subscribers[imsi];
    if (subscriber != null) {
      // Respond with Authentication-Information-Answer (AIA)
      socket
          .add(utf8.encode('AIA:' + imsi + ':' + subscriber.authenticationKey));
    } else {
      // Subscriber not found, send error response
      socket.add(utf8.encode('Subscriber not found'));
    }
  }

  // Method to handle Insert-Subscriber-Data (ISD) messages
  void handleIsdRequest(Socket socket, List<int> request) {
    // Parse request and extract subscriber information
    List<String> parts = utf8.decode(request).split(':');
    if (parts.length == 3) {
      String imsi = parts[0];
      String msisdn = parts[1];
      String authenticationKey = parts[2];

      // Add subscriber to the database
      _subscribers[imsi] = Subscriber(
          imsi: imsi, msisdn: msisdn, authenticationKey: authenticationKey);

      // Respond with Insert-Subscriber-Data-Answer (ISA)
      socket.add(utf8.encode('ISA:Success'));
    } else {
      // Invalid request, send error response
      socket.add(utf8.encode('Invalid request'));
    }
  }
}

void main() async {
  HssServer hssServer = HssServer();

  try {
    // Start the Diameter server
    ServerSocket server = await ServerSocket.bind('127.0.0.1', 3868);
    print('HSS server listening on port ${server.port}');

    // Listen for incoming connections
    await for (Socket socket in server) {
      // Handle incoming messages
      socket.listen((List<int> data) {
        String message = utf8.decode(data);
        if (message.startsWith('AIR')) {
          // Authentication-Information-Request (AIR) message received
          hssServer.handleAirRequest(
              socket, data.sublist(4)); // Remove 'AIR:' prefix
        } else if (message.startsWith('ISD')) {
          // Insert-Subscriber-Data (ISD) message received
          hssServer.handleIsdRequest(
              socket, data.sublist(4)); // Remove 'ISD:' prefix
        } else {
          // Unsupported message, send error response
          socket.add(utf8.encode('Unsupported message'));
        }
      });
    }
  } catch (e) {
    print('Error starting HSS server: $e');
  }
}
