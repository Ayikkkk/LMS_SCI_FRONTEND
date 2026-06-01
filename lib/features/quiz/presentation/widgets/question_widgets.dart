// lib/features/quiz/presentation/widgets/question_widgets.dart

import 'package:flutter/material.dart';
import '../../domain/models/question_model.dart';
import '../../domain/quiz_notifier.dart';

/// Multiple Choice Question (Single Selection)
class MultipleChoiceWidget extends StatelessWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: question.options.map((opt) {
        final selected = notifier.selectedAnswers[question.id] == opt.id;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Radio<String>(
              value: opt.id,
              groupValue: notifier.selectedAnswers[question.id] as String?,
              onChanged: (value) {
                if (value != null) {
                  notifier.selectOption(question.id, value);
                }
              },
            ),
            title: Text(
              opt.text,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            tileColor: selected ? Colors.blue.shade50 : null,
            onTap: () => notifier.selectOption(question.id, opt.id),
          ),
        );
      }).toList(),
    );
  }
}

/// Multiple Answer Question (Multiple Selection)
class MultipleAnswerWidget extends StatelessWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const MultipleAnswerWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Pilih semua jawaban yang benar',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: question.options.map((opt) {
              final selected =
                  notifier.isMultipleOptionSelected(question.id, opt.id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: selected,
                  onChanged: (value) {
                    notifier.toggleMultipleOption(question.id, opt.id);
                  },
                  title: Text(
                    opt.text,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  tileColor: selected ? Colors.green.shade50 : null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// True/False Question
class TrueFalseWidget extends StatelessWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const TrueFalseWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            context,
            'true',
            'Benar',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            'false',
            'Salah',
            Icons.cancel,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = notifier.selectedAnswers[question.id] == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      child: Card(
        elevation: selected ? 8 : 2,
        color: selected ? color.withOpacity(0.1) : null,
        child: InkWell(
          onTap: () => notifier.selectOption(question.id, value),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 48, color: selected ? color : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? color
                        : (isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yes/No Question
class YesNoWidget extends StatelessWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const YesNoWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            context,
            'yes',
            'Ya',
            Icons.thumb_up,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context,
            'no',
            'Tidak',
            Icons.thumb_down,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final selected = notifier.selectedAnswers[question.id] == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      child: Card(
        elevation: selected ? 8 : 2,
        color: selected ? color.withOpacity(0.1) : null,
        child: InkWell(
          onTap: () => notifier.selectOption(question.id, value),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(icon, size: 48, color: selected ? color : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? color
                        : (isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Short Answer / Fill in the Blank Widget
class ShortAnswerWidget extends StatefulWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const ShortAnswerWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  State<ShortAnswerWidget> createState() => _ShortAnswerWidgetState();
}

class _ShortAnswerWidgetState extends State<ShortAnswerWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.notifier.getTextAnswer(widget.question.id),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masukkan jawaban Anda:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLength: widget.question.maxLength ?? 200,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: 'Ketik jawaban di sini...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor:
                  isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            onChanged: (value) {
              widget.notifier.setTextAnswer(widget.question.id, value);
            },
          ),
        ],
      ),
    );
  }
}

/// Essay / Description Widget
class EssayWidget extends StatefulWidget {
  final QuestionModel question;
  final QuizNotifier notifier;

  const EssayWidget({
    super.key,
    required this.question,
    required this.notifier,
  });

  @override
  State<EssayWidget> createState() => _EssayWidgetState();
}

class _EssayWidgetState extends State<EssayWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.notifier.getTextAnswer(widget.question.id),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tulis jawaban Anda dengan lengkap:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLength: widget.question.maxLength ?? 1000,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Ketik jawaban Anda di sini...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor:
                    isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              ),
              onChanged: (value) {
                widget.notifier.setTextAnswer(widget.question.id, value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
