import 'dart:async';
import 'package:flutter/material.dart';
import '../data/ride_chat_api.dart';

class DriverChatScreen extends StatefulWidget {
  const DriverChatScreen({
    super.key,
    required this.rideId,
    required this.passengerName,
    this.passengerPhotoUrl,
  });
  final String rideId;
  final String passengerName;
  final String? passengerPhotoUrl;
  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final _api = RideChatApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<RideChatMessage> _messages = const [];
  Timer? _timer;
  bool _loading = true;
  bool _sending = false;
  bool _chatClosed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final messages = await _api.list(widget.rideId);
      await _api.markRead(widget.rideId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('encerrado após o término')) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _loading = false;
            _error = message;
            _chatClosed = true;
          });
        }
        return;
      }
      if (mounted && _messages.isEmpty)
        setState(() {
          _loading = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await _api.send(widget.rideId, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _input.clear();
      });
    } catch (error) {
      if (error.toString().contains('encerrado após o término') && mounted) {
        _timer?.cancel();
        setState(() => _chatClosed = true);
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0F18),
        foregroundColor: Colors.white,
        title: const Text('Chat com passageiro'),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0C0F18),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (widget.passengerPhotoUrl?.isNotEmpty ?? false)
                          ? NetworkImage(widget.passengerPhotoUrl!)
                          : null,
                  child:
                      (widget.passengerPhotoUrl?.isEmpty ?? true)
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.passengerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC62F78),
                      ),
                    )
                    : _error != null && _messages.isEmpty
                    ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final message = _messages[i];
                        return Align(
                          alignment:
                              message.isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            constraints: const BoxConstraints(maxWidth: 310),
                            decoration: BoxDecoration(
                              color:
                                  message.isMine
                                      ? const Color(0xFFC62F78)
                                      : const Color(0xFF202A3D),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.content,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_sending && !_chatClosed,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF202A3D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending || _chatClosed ? null : _send,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFC62F78),
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
