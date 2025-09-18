import 'package:flutter/material.dart';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String? difficulty;
  final int? order;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.difficulty,
    this.order,
  });

  factory Question.fromApi(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'],
      order: json['order'],
    );
  }
}

class QuizCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Question> questions;
  final Color color;
  final int? timeLimit;
  final bool? isPublic;
  final int? questionCount;
  final int? attemptCount;
  final DateTime? createdAt;
  final String? createdBy;

  QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.questions,
    required this.color,
    this.timeLimit,
    this.isPublic,
    this.questionCount,
    this.attemptCount,
    this.createdAt,
    this.createdBy,
  });

  QuizCategory copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    List<Question>? questions,
    Color? color,
    int? timeLimit,
    bool? isPublic,
    int? questionCount,
    int? attemptCount,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return QuizCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      questions: questions ?? this.questions,
      color: color ?? this.color,
      timeLimit: timeLimit ?? this.timeLimit,
      isPublic: isPublic ?? this.isPublic,
      questionCount: questionCount ?? this.questionCount,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory QuizCategory.fromApi(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'] ?? '',
      name: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromString(json['icon'] ?? ''),
      color: _getColorFromString(json['color'] ?? ''),
      questions: json['questions'] != null
          ? (json['questions'] as List).map((q) => Question.fromApi(q)).toList()
          : [],
      timeLimit: json['timeLimit'],
      isPublic: json['isPublic'] ?? true,
      questionCount: json['questionCount'] ?? json['_count']?['questions'] ?? 0,
      attemptCount: json['attemptCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      createdBy: json['createdBy'] ?? '',
    );
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'calculate':
        return Icons.calculate;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'access_time':
        return Icons.access_time;
      case 'speed':
        return Icons.speed;
      case 'trending_up':
        return Icons.trending_up;
      case 'account_balance':
        return Icons.account_balance;
      case 'crop_square':
        return Icons.crop_square;
      case 'format_list_numbered':
        return Icons.format_list_numbered;
      case 'psychology':
        return Icons.psychology;
      case 'public':
        return Icons.public;
      default:
        return Icons.quiz;
    }
  }

  static Color _getColorFromString(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class QuizSession {
  final String categoryId;
  final List<int> userAnswers;
  final int currentQuestionIndex;
  final DateTime startTime;
  final bool isCompleted;
  final int score;

  QuizSession({
    required this.categoryId,
    required this.userAnswers,
    required this.currentQuestionIndex,
    required this.startTime,
    required this.isCompleted,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'userAnswers': userAnswers,
      'currentQuestionIndex': currentQuestionIndex,
      'startTime': startTime.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'score': score,
    };
  }

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      categoryId: json['categoryId'],
      userAnswers: List<int>.from(json['userAnswers']),
      currentQuestionIndex: json['currentQuestionIndex'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      isCompleted: json['isCompleted'],
      score: json['score'],
    );
  }
}
