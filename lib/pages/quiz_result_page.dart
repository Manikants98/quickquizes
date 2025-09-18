import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/storage_service.dart';
import 'quiz_detail_page.dart';

class QuizResultPage extends StatelessWidget {
  final QuizCategory category;
  final List<int> userAnswers;
  final int score;

  const QuizResultPage({
    super.key,
    required this.category,
    required this.userAnswers,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / category.questions.length * 100).round();
    final isGoodScore = percentage >= 70;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: category.color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: Theme.of(context).brightness == Brightness.dark
                  ? 12
                  : 8,
              shadowColor: Theme.of(context).colorScheme.shadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.5
                    : 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      category.color.withValues(alpha: 0.8),
                      category.color,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isGoodScore
                          ? Icons.emoji_events
                          : Icons.sentiment_satisfied,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isGoodScore ? 'Excellent!' : 'Good Effort!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score out of ${category.questions.length}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Performance breakdown
            Card(
              elevation: Theme.of(context).brightness == Brightness.dark
                  ? 4
                  : 2,
              shadowColor: Theme.of(context).colorScheme.shadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.3
                    : 0.15,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Correct',
                            score.toString(),
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Incorrect',
                            (category.questions.length - score).toString(),
                            Colors.red,
                            Icons.cancel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Accuracy',
                            '$percentage%',
                            category.color,
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Review answers button
            SizedBox(
              height: 160,
              child: Card(
                elevation: Theme.of(context).brightness == Brightness.dark
                    ? 3
                    : 1,
                shadowColor: Theme.of(context).colorScheme.shadow.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.25
                      : 0.1,
                ),
                child: InkWell(
                  onTap: () => _showAnswerReview(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 48,
                          color: category.color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Review Answers',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'See correct answers and explanations',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: category.color,
                      side: BorderSide(color: category.color),
                      textStyle: Theme.of(context).textTheme.bodyMedium,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _retakeQuiz(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: category.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.3,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Answer Review',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // Content
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: category.questions.length,
                itemBuilder: (context, index) {
                  final question = category.questions[index];
                  final userAnswer = userAnswers[index];
                  final correctAnswer = question.correctAnswer;
                  final isCorrect = userAnswer == correctAnswer;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: Theme.of(context).brightness == Brightness.dark
                        ? 3
                        : 1,
                    shadowColor: Theme.of(context).colorScheme.shadow
                        .withOpacity(
                          Theme.of(context).brightness == Brightness.dark
                              ? 0.25
                              : 0.1,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Q${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question.question,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ...question.options.asMap().entries.map((entry) {
                            final optionIndex = entry.key;
                            final option = entry.value;
                            final isUserAnswer = userAnswer == optionIndex;
                            final isCorrectOption =
                                correctAnswer == optionIndex;

                            Color? backgroundColor;
                            Color? textColor;
                            IconData? icon;

                            if (isCorrectOption) {
                              backgroundColor = Colors.green.withOpacity(0.1);
                              textColor = Colors.green;
                              icon = Icons.check;
                            } else if (isUserAnswer && !isCorrect) {
                              backgroundColor = Colors.red.withOpacity(0.1);
                              textColor = Colors.red;
                              icon = Icons.close;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: backgroundColor != null
                                      ? (textColor ?? Colors.transparent)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${String.fromCharCode(65 + optionIndex)}. $option',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight:
                                            (isUserAnswer || isCorrectOption)
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (icon != null)
                                    Icon(icon, color: textColor, size: 16),
                                ],
                              ),
                            );
                          }).toList(),
                          if (question.explanation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: category.color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: category.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Explanation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: category.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    question.explanation,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.8),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retakeQuiz(BuildContext context) async {
    await StorageService.clearQuizSession(category.id);

    if (!context.mounted) return;
    Navigator.of(
      context,
    ).popUntil((route) => route.settings.name == '/quiz_list' || route.isFirst);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailPage(category: category),
      ),
    );
  }
}
