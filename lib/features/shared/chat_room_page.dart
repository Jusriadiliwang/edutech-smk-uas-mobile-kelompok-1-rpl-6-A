import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isConfidential;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.title,
    this.isConfidential = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _uid         = FirebaseAuth.instance.currentUser!.uid;
  bool _sending      = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.chats)
          .doc(widget.chatId)
          .collection(FirebaseConstants.messages)
          .add({
        'sender_id':  _uid,
        'text':       text,
        'created_at': FieldValue.serverTimestamp(),
        'read':       false,
      });

      // Scroll ke bawah
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.isConfidential)
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.colorBK.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.lock_outline, size: 14, color: AppTheme.colorBK),
              ),
            Expanded(child: Text(widget.title)),
          ],
        ),
        actions: [
          if (widget.isConfidential)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.colorBK.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('CONFIDENTIAL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.colorBK)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Confidential info banner
          if (widget.isConfidential)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.colorBK.withOpacity(0.06),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: AppTheme.colorBK),
                  SizedBox(width: 6),
                  Text(
                    'Percakapan ini bersifat rahasia antara Guru BK dan Siswa.',
                    style: TextStyle(fontSize: 11, color: AppTheme.colorBK),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.chats)
                  .doc(widget.chatId)
                  .collection(FirebaseConstants.messages)
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data!.docs;

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isConfidential ? Icons.lock_outline : Icons.chat_bubble_outline,
                          size: 48, color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text('Belum ada pesan.', style: TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        const Text('Mulai percakapan di bawah.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }

                // Auto scroll ke bawah saat ada pesan baru
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final isMine = data['sender_id'] == _uid;
                    final time   = (data['created_at'] as Timestamp?)?.toDate();

                    // Date separator
                    final showDateSep = i == 0 || (i > 0 && _isDifferentDay(
                      (msgs[i - 1].data() as Map)['created_at'] as Timestamp?,
                      data['created_at'] as Timestamp?,
                    ));

                    return Column(
                      children: [
                        if (showDateSep && time != null)
                          _DateSeparator(date: time),
                        _MessageBubble(
                          text: data['text'] ?? '',
                          isMine: isMine,
                          time: time,
                          isConfidential: widget.isConfidential,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: widget.isConfidential ? 'Tulis pesan confidential...' : 'Tulis pesan...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: widget.isConfidential ? AppTheme.colorBK : AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      onPressed: _sending ? null : _send,
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

  bool _isDifferentDay(Timestamp? a, Timestamp? b) {
    if (a == null || b == null) return false;
    final da = a.toDate();
    final db = b.toDate();
    return da.year != db.year || da.month != db.month || da.day != db.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? time;
  final bool isConfidential;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    this.time,
    this.isConfidential = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? (isConfidential ? AppTheme.colorBK : AppTheme.primary)
        : Colors.white;
    final textColor   = isMine ? Colors.white : AppTheme.textPrimary;
    final timeColor   = isMine ? Colors.white.withOpacity(0.65) : AppTheme.textMuted;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3, bottom: 3,
          left: isMine ? 60 : 0,
          right: isMine ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(color: textColor, fontSize: 14, height: 1.4)),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(DateFormat('HH:mm').format(time!),
                  style: TextStyle(color: timeColor, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'Hari ini';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Kemarin';
    } else {
      label = DateFormat('d MMMM yyyy', 'id_ID').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
