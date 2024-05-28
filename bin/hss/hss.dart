import 'dart:convert';

class Subscriber {
  final String imsi;
  final String msisdn;
  final String authenticationKey;
  final String ipAddress; // Example field for subscriber's current IP address

  Subscriber({
    required this.imsi,
    required this.msisdn,
    required this.authenticationKey,
    required this.ipAddress,
  });
}

class HssServer {
  final Map<String, Subscriber> _subscribers = {}; // In-memory database for subscribers

  // Method to add a new subscriber
  void addSubscriber(Subscriber subscriber) {
    _subscribers[subscriber.imsi] = subscriber;
  }

  // Method to authenticate a subscriber
  bool authenticateSubscriber(String imsi, String authenticationKey) {
    Subscriber? subscriber = _subscribers[imsi];
    if (subscriber != null && subscriber.authenticationKey == authenticationKey) {
      return true; // Authentication successful
    }
    return false; // Authentication failed
  }

  // Method to get subscriber information by IMSI
  Subscriber? getSubscriberByImsi(String imsi) {
    return _subscribers[imsi];
  }
}

void main() {
  // Create an instance of the HSS server
  HssServer hssServer = HssServer();

  // Add some subscribers to the HSS server
  Subscriber subscriber1 = Subscriber(
    imsi: '123456789012345',
    msisdn: '+1234567890',
    authenticationKey: 'abcdef123456',
    ipAddress: '192.168.1.100',
  );
  hssServer.addSubscriber(subscriber1);

  Subscriber subscriber2 = Subscriber(
    imsi: '987654321098765',
    msisdn: '+9876543210',
    authenticationKey: '654321abcdef',
    ipAddress: '192.168.1.101',
  );
  hssServer.addSubscriber(subscriber2);

  // Authenticate a subscriber
  String imsiToAuthenticate = '123456789012345';
  String authenticationKeyToUse = 'abcdef123456';
  if (hssServer.authenticateSubscriber(imsiToAuthenticate, authenticationKeyToUse)) {
    print('Authentication successful for IMSI: $imsiToAuthenticate');
  } else {
    print('Authentication failed for IMSI: $imsiToAuthenticate');
  }

  // Get subscriber information by IMSI
  String imsiToQuery = '987654321098765';
  Subscriber? queriedSubscriber = hssServer.getSubscriberByImsi(imsiToQuery);
  if (queriedSubscriber != null) {
    print('Subscriber information for IMSI: $imsiToQuery');
    print('MSISDN: ${queriedSubscriber.msisdn}');
    print('IP Address: ${queriedSubscriber.ipAddress}');
  } else {
    print('Subscriber with IMSI $imsiToQuery not found');
  }
}
