import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> targetUser;

  const ChatScreen({super.key, required this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  IO.Socket? socket;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isConnected = false;
  bool isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDisposed = false; // Additional safety flag

  @override
  void initState() {
    super.initState();
    print("Widget initialized!");
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _initializeSocket();
  }

  /// Safe setState helper
  void safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      try {
        setState(fn);
      } catch (e) {
        print('Safe setState error: $e');
      }
    }
  }

  /// Safe scroll helper
  void safeScrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeSocket() async {
    if (!mounted) return;

    safeSetState(() {
      messages.clear();
      isConnected = false;
    });

    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    // Disconnect existing socket if any
    if (socket != null) {
      try {
        socket!.clearListeners();
        socket!.disconnect();
        socket!.dispose();
      } catch (e) {
        print('Error cleaning up old socket: $e');
      }
      socket = null;
    }

    final token = await AuthService().getToken();
    if (token == null) {
      print('❌ No token found');
      return;
    }

    socket = IO.io(
      'http://192.168.1.59:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setTimeout(10000) // 10 second timeout
          .build(),
    );

    socket!.connect();

    // Connection established
    socket!.onConnect((_) {
      print('✅ Connected to socket');
      if (!mounted || _isDisposed) return;

      safeSetState(() => isConnected = true);
      _animationController.forward();

      // Load history after connection
      socket!.emit('load-history', {
        'targetUserId': widget.targetUser['_id']
      });
    });

    // Chat history loaded
    socket!.on('chat-history', (data) {
      print('📜 Chat history: $data');
      if (!mounted || _isDisposed) return;

      safeSetState(() {
        messages = List<Map<String, dynamic>>.from(data.map((msg) => {
          'text': msg['text'],
          'from': msg['from'] == widget.targetUser['_id'] ? 'other' : 'me',
          'timestamp': msg['timestamp'] ?? DateTime.now().toIso8601String(),
          'delivered': true,
        }));
      });
      safeScrollToBottom();
    });

    // New message received
    socket!.on('receive-message', (data) {
      print('📩 Received: $data');
      if (!mounted || _isDisposed) return;

      safeSetState(() {
        messages.add({
          'text': data['text'],
          'from': data['from'] == widget.targetUser['_id'] ? 'other' : 'me',
          'timestamp': DateTime.now().toIso8601String(),
          'delivered': true,
        });
      });
      safeScrollToBottom();
    });

    // Connection lost
    socket!.onDisconnect((_) {
      print('🔴 Socket disconnected');
      if (!mounted || _isDisposed) return;

      safeSetState(() => isConnected = false);
    });

    // Connection error
    socket!.onConnectError((err) {
      print('❌ Connection error: $err');
      if (!mounted || _isDisposed) return;

      safeSetState(() => isConnected = false);
    });

    // Reconnection attempt
    socket!.onReconnectAttempt((data) {
      print('🔄 Reconnection attempt: $data');
    });

    // Reconnected successfully
    socket!.onReconnect((data) {
      print('🔄 Reconnected: $data');
      if (!mounted || _isDisposed) return;

      safeSetState(() => isConnected = true);
      _animationController.forward();
    });
  }

  void sendMessage() {
    if (!isConnected || _controller.text.trim().isEmpty) return;

    final msg = _controller.text.trim();
    socket!.emit('send-message', {
      'toUserId': widget.targetUser['_id'],
      'text': msg,
    });

    safeSetState(() {
      messages.add({
        'text': msg,
        'from': 'me',
        'timestamp': DateTime.now().toIso8601String(),
        'delivered': false,
      });
      _controller.clear();
      isTyping = false;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
    safeScrollToBottom();
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Now';
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing ChatScreen...');
    _isDisposed = true; // Set flag immediately

    // Clean up socket completely
    if (socket != null) {
      try {
        socket!.clearListeners();
        socket!.disconnect();
        socket!.dispose();
      } catch (e) {
        print('Error disposing socket: $e');
      }
      socket = null;
    }

    // Dispose controllers
    _animationController.dispose();
    _scrollController.dispose();
    _controller.dispose();

    super.dispose();
    print('✅ ChatScreen disposed');
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.targetUser['firstName']} ${widget.targetUser['lastName']}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : const Color(0xFFE5DDD5),
      appBar: AppBar(
        elevation: 2,
        shadowColor: Colors.black26,
        backgroundColor: isDark ? const Color(0xFF1F2C34) : const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Text(
                name.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      isConnected ? 'Online' : 'Connecting...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'view_contact',
                child: Text('View contact'),
              ),
              const PopupMenuItem(
                value: 'media',
                child: Text('Media, links, and docs'),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Text('Search'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['from'] == 'me';
                final showTimeStamp = index == 0 ||
                    index == messages.length - 1 ||
                    (index > 0 && messages[index - 1]['from'] != msg['from']);

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutBack,
                  child: ChatBubble(
                    message: msg['text'],
                    isMe: isMe,
                    timestamp: _formatTime(msg['timestamp'] ?? ''),
                    showTimestamp: showTimeStamp,
                    delivered: msg['delivered'] ?? false,
                  ),
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              // Show emoji picker
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type a message',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (text) {
                                safeSetState(() {
                                  isTyping = text.trim().isNotEmpty;
                                });
                              },
                              onSubmitted: (_) => sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.attach_file,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              // Handle file attachment
                            },
                          ),
                          if (!isTyping)
                            IconButton(
                              icon: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                // Handle camera
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: const Color(0xFF128C7E),
                      borderRadius: BorderRadius.circular(25),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: isConnected && isTyping ? sendMessage : null,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: isConnected && isTyping
                                ? const LinearGradient(
                              colors: [Color(0xFF128C7E), Color(0xFF25D366)],
                            )
                                : null,
                            color: isConnected && isTyping
                                ? null
                                : Colors.grey[400],
                          ),
                          child: Icon(
                            isTyping ? Icons.send : Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ChatBubble remains unchanged
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String timestamp;
  final bool showTimestamp;
  final bool delivered;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.showTimestamp,
    required this.delivered,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 64.0 : 16.0,
        4,
        isMe ? 16.0 : 64.0,
        4,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                  colors: [Color(0xFF128C7E), Color(0xFF25D366)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isMe
                    ? null
                    : isDark
                    ? const Color(0xFF1F2C34)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe
                          ? Colors.white
                          : isDark
                          ? Colors.white
                          : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showTimestamp) ...[
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white70
                                : isDark
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
                      ],
                      if (isMe)
                        Icon(
                          delivered ? Icons.done_all : Icons.done,
                          size: 16,
                          color: delivered
                              ? Colors.blue[300]
                              : Colors.white70,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}