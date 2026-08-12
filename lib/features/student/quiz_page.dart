import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class QuizPage extends StatefulWidget {
  final String quizId, studentId;
  final Map<String, dynamic> quizData;
  const QuizPage({super.key, required this.quizId, required this.studentId, required this.quizData});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _current = 0;
  final Map<int, int> _answers = {};  // questionIndex → selectedOption
  bool _submitted = false;
  int? _score;
  late int _secondsLeft;
  Timer? _timer;
  bool _loading = false;

  List<Map<String, dynamic>> get _questions =>
      (widget.quizData['questions'] as List? ?? [])
          .map((q) => Map<String, dynamic>.from(q as Map)).toList();

  @override
  void initState() {
    super.initState();
    final duration = widget.quizData['duration'] as int? ?? 30;
    _secondsLeft = duration * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _submitQuiz();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_submitted || _loading) return;
    _timer?.cancel();
    setState(() => _loading = true);

    // Hitung skor
    int correct = 0;
    final questions = _questions;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final correctIdx = q['answer'] as int? ?? 0;
      if (_answers[i] == correctIdx) correct++;
    }
    final score = questions.isEmpty ? 0 : (correct / questions.length * 100).round();

    await FirebaseFirestore.instance.collection(FirebaseConstants.quizAnswers).add({
      'quiz_id':    widget.quizId,
      'student_id': widget.studentId,
      'answers':    _answers.map((k, v) => MapEntry(k.toString(), v)),
      'score':      score,
      'correct':    correct,
      'total':      questions.length,
      'submitted_at': DateTime.now(),
    });

    setState(() { _submitted = true; _score = score; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;

    if (_submitted) {
      final color = (_score ?? 0) >= 75 ? AppTheme.secondary : (_score ?? 0) >= 60 ? AppTheme.warning : AppTheme.danger;
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(title: const Text('Hasil Kuis')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon((_score ?? 0) >= 75 ? Icons.emoji_events : Icons.assignment_turned_in,
                  size: 80, color: color),
              const SizedBox(height: 20),
              Text('Kuis Selesai!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(widget.quizData['title'] ?? '',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Text('Nilai Kamu', style: TextStyle(color: color, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$_score', style: TextStyle(color: color, fontSize: 64, fontWeight: FontWeight.w900)),
                  Text('dari 100', style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),
              Text((_score ?? 0) >= 75 ? 'Selamat! Kamu lulus kuis ini.' :
                   (_score ?? 0) >= 60 ? 'Hampir! Terus belajar ya.' :
                   'Jangan menyerah! Pelajari kembali materinya.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ]),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizData['title'] ?? 'Kuis')),
        body: const Center(child: Text('Belum ada pertanyaan.', style: TextStyle(color: AppTheme.textMuted))),
      );
    }

    final q = questions[_current];
    final options = (q['options'] as List? ?? []).map((o) => o.toString()).toList();
    final timerColor = _secondsLeft < 60 ? AppTheme.danger : _secondsLeft < 180 ? AppTheme.warning : AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.quizData['title'] ?? 'Kuis'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: timerColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.timer, size: 16, color: timerColor),
              const SizedBox(width: 4),
              Text(_timerText, style: TextStyle(color: timerColor, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // Progress
        LinearProgressIndicator(
          value: (_current + 1) / questions.length,
          backgroundColor: AppTheme.border,
          color: AppTheme.primary,
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Soal ${_current + 1} dari ${questions.length}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                Text('${_answers.length} dijawab',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ]),
              const SizedBox(height: 16),

              // Question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(q['question'] as String? ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
              ),
              const SizedBox(height: 20),

              // Options
              ...List.generate(options.length, (idx) {
                final selected = _answers[_current] == idx;
                return GestureDetector(
                  onTap: () => setState(() => _answers[_current] = idx),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppTheme.primary : AppTheme.bg,
                          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Center(
                          child: selected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(String.fromCharCode(65 + idx),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(options[idx],
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? AppTheme.primary : AppTheme.textPrimary))),
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ),

        // Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(children: [
            if (_current > 0)
              OutlinedButton.icon(
                onPressed: () => setState(() => _current--),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Sebelumnya'),
              ),
            const Spacer(),
            if (_current < questions.length - 1)
              ElevatedButton.icon(
                onPressed: () => setState(() => _current++),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Berikutnya'),
              )
            else
              ElevatedButton.icon(
                onPressed: _loading ? null : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Kumpulkan Kuis?'),
                      content: Text('Kamu telah menjawab ${_answers.length} dari ${questions.length} soal. Yakin kumpulkan?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kumpulkan')),
                      ],
                    ),
                  );
                  if (confirm == true) _submitQuiz();
                },
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 18),
                label: const Text('Kumpulkan'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
              ),
          ]),
        ),
      ]),
    );
  }
}
