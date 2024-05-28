import 'dart:convert';
import 'dart:io';

// Subscriber class to hold subscriber information
class Subscriber {
  final String imsi;
  final String msisdn;
  final String authenticationKey;

  Subscriber({required this.imsi, required this.msisdn, required this.authenticationKey});
}

// Home Subscriber Server class
class HssServer {
  final Map<String, Subscriber> _subscribers = {
    '123456789012345': Subscriber(imsi: '123456789012345', msisdn: '+1234567890', authenticationKey: 'abcdef123456'),
    '987654321098765': Subscriber(imsi: '987654321098765', msisdn: '+9876543210', authenticationKey: '654321abcdef'),
  };

  // Method to handle Authentication-Information-Request (AIR) messages
  void handleAirRequest(Socket socket, List<int> request) {
    String imsi = utf8.decode(request);
    Subscriber? subscriber = _subscribers[imsi];
    if (subscriber != null) {
      // Respond with Authentication-Information-Answer (AIA)
      socket.add(utf8.encode(imsi + ':' + subscriber.authenticationKey));
    } else {
      // Subscriber not found, send error response
      socket.add(utf8.encode('Subscriber not found'));
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
          hssServer.handleAirRequest(socket, data.sublist(3)); // Remove 'AIR' prefix
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
