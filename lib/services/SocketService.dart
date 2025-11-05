import 'package:socket_io_client/socket_io_client.dart' as IO;

void connectSocket(String token) {
  final socket = IO.io(
    'http://192.168.1.59:5000',
    IO.OptionBuilder()
        .setTransports(['websocket']) // ✅ Important for Flutter
        .setAuth({'token': token}) // ✅ Same key name as server expects
        .enableReconnection() // Optional, auto reconnects
        .build(),
  );

  socket.onConnect((_) {
    print('✅ Socket connected successfully');
  });

  socket.onConnectError((err) {
    print('❌ Socket connect error: $err');
  });

  socket.onDisconnect((_) {
    print('🔴 Socket disconnected');
  });

  socket.on('receive-message', (data) {
    print('📩 Message received: $data');
  });
}
