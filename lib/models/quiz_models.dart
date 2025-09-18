import 'package:flutter/material.dart';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromApi(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
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

  QuizCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.questions,
    required this.color,
  });

  factory QuizCategory.fromApi(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: _getIconFromString(json['icon']),
      color: _getColorFromString(json['color']),
      questions: json['questions'] != null 
          ? (json['questions'] as List).map((q) => Question.fromApi(q)).toList()
          : [],
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
