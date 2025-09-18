import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'quiz_result_page.dart';

class QuizDetailPage extends StatefulWidget {
  final QuizCategory category;

  const QuizDetailPage({super.key, required this.category});

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  int currentQuestionIndex = 0;
  List<int> userAnswers = [];
  Timer? _timer;
  int timeRemaining = 1800; // 30 minutes in seconds
  bool isQuizCompleted = false;
  QuizSession? currentSession;
  List<Question> questions = [];
  bool isLoadingQuestions = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
  }

  Future<void> _loadQuizQuestions() async {
    try {
      setState(() {
        isLoadingQuestions = true;
        errorMessage = null;
      });

      // First try to get questions from the category (if already loaded)
      if (widget.category.questions.isNotEmpty) {
        questions = widget.category.questions;
      } else {
        // Fetch questions from API
        questions = await ApiService.getAllQuizQuestions(widget.category.id);
      }

      if (questions.isEmpty) {
        setState(() {
          errorMessage = 'No questions found for this quiz';
          isLoadingQuestions = false;
        });
        return;
      }

      // Sort questions by order if available
      questions.sort((a, b) {
        if (a.order != null && b.order != null) {
          return a.order!.compareTo(b.order!);
        }
        return 0;
      });

      setState(() {
        isLoadingQuestions = false;
      });

      _initializeQuiz();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load quiz questions: $e';
        isLoadingQuestions = false;
      });
    }
  }

  void _initializeQuiz() async {
    // Initialize user answers list
    userAnswers = List.filled(questions.length, -1);

    // Set time limit from quiz data or default
    final quizTimeLimit = widget.category.timeLimit ?? 30;
    timeRemaining = quizTimeLimit * 60; // Convert minutes to seconds

    // Try to load existing session
    currentSession = await StorageService.getQuizSession(widget.category.id);

    if (currentSession != null && !currentSession!.isCompleted) {
      setState(() {
        currentQuestionIndex = currentSession!.currentQuestionIndex;
        userAnswers = List.from(currentSession!.userAnswers);
        final elapsed = DateTime.now()
            .difference(currentSession!.startTime)
            .inSeconds;
        timeRemaining = (quizTimeLimit * 60 - elapsed).clamp(
          0,
          quizTimeLimit * 60,
        );
      });
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _saveSession() async {
    final session = QuizSession(
      categoryId: widget.category.id,
      userAnswers: userAnswers,
      currentQuestionIndex: currentQuestionIndex,
      startTime: currentSession?.startTime ?? DateTime.now(),
      isCompleted: isQuizCompleted,
      score: _calculateScore(),
    );

    await StorageService.saveQuizSession(session);
  }

  int _calculateScore() {
    int score = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (userAnswers[i] == questions[i].correctAnswer) {
        score++;
      }
    }
    return score;
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      userAnswers[currentQuestionIndex] = answerIndex;
    });
    _saveSession();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _saveSession();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
      _saveSession();
    }
  }

  void _submitQuiz() async {
    _timer?.cancel();

    final score = _calculateScore();
    final timeSpent = (widget.category.timeLimit ?? 30) * 60 - timeRemaining; // Calculate time spent in seconds
    
    // Save score locally
    await StorageService.saveScore(widget.category.id, score, questions.length);
    
    // Save score to backend
    try {
      print('🎯 Attempting to save score to backend:');
      print('Category ID: ${widget.category.id}');
      print('Score: $score');
      print('Total Questions: ${questions.length}');
      print('Time Spent: ${timeSpent ~/ 60} minutes');
      
      await ApiService.saveQuizScore(
        widget.category.id,
        score,
        questions.length,
        (score / questions.length * 100).round(),
        timeSpent ~/ 60, // Convert to minutes
      );
      
      print('✅ Score saved to backend successfully');
    } catch (e) {
      print('❌ Failed to save score to backend: $e');
      // Continue with local storage even if backend fails
    }

    await StorageService.clearQuizSession(widget.category.id);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultPage(
            category: widget.category.copyWith(questions: questions),
            userAnswers: userAnswers,
            score: score,
          ),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildQuizDetailSkeleton() {
    return Column(
      children: [
        // Progress bar skeleton
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonText(width: 120, height: 16),
                  SkeletonText(width: 100, height: 16),
                ],
              ),
              const SizedBox(height: 8),
              SkeletonLoader(
                width: double.infinity,
                height: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),

        // Question card skeleton
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number and difficulty
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SkeletonText(width: 80, height: 14),
                            SkeletonLoader(
                              width: 60,
                              height: 20,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Question text
                        SkeletonText(width: double.infinity, height: 18),
                        const SizedBox(height: 8),
                        SkeletonText(width: 280, height: 18),
                        const SizedBox(height: 8),
                        SkeletonText(width: 200, height: 18),
                        const SizedBox(height: 24),
                        
                        // Answer options
                        ...List.generate(4, (index) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SkeletonAvatar(size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SkeletonText(
                                      width: double.infinity, 
                                      height: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Navigation buttons skeleton
                Row(
                  children: [
                    Expanded(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 48,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoadingQuestions) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
        ),
        body: _buildQuizDetailSkeleton(),
      );
    }

    // Show error state
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuizQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if questions list is empty
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This quiz doesn\'t have any questions yet.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        titleSpacing: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 4),
                Text(
                  _formatTime(timeRemaining),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1} of ${questions.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).round()}% Complete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: Theme.of(context).brightness == Brightness.dark
                        ? 4
                        : 2,
                    shadowColor: Theme.of(context).colorScheme.shadow
                        .withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.3
                              : 0.15,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Answer options
                  Expanded(
                    child: ListView.builder(
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        final isSelected =
                            userAnswers[currentQuestionIndex] == index;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: isSelected
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 6
                                      : 4)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 2
                                      : 1),
                            shadowColor: Theme.of(context).colorScheme.shadow
                                .withValues(
                                  alpha:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.4
                                      : 0.2,
                                ),
                            color: isSelected
                                ? widget.category.color.withValues(
                                    alpha:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 0.2
                                        : 0.1,
                                  )
                                : null,
                            child: InkWell(
                              onTap: () => _selectAnswer(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? widget.category.color
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? widget.category.color
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        '${String.fromCharCode(65 + index)}. ${question.options[index]}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? (Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : widget.category.color)
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.category.color,
                        side: BorderSide(color: widget.category.color),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (currentQuestionIndex > 0) const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentQuestionIndex < questions.length - 1
                        ? _nextQuestion
                        : _submitQuiz,
                    icon: Icon(
                      currentQuestionIndex < questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      currentQuestionIndex < questions.length - 1
                          ? 'Next'
                          : 'Submit Quiz',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.category.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
