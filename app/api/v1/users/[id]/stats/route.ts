import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const userId = params.id;

    if (!userId) {
      return NextResponse.json(
        { success: false, error: "User ID is required" },
        { status: 400 }
      );
    }

    // Get user's quiz attempts
    const quizAttempts = await prisma.quizAttempt.findMany({
      where: {
        userId: userId,
        status: "COMPLETED",
      },
      include: {
        quiz: true,
      },
    });

    // Calculate overall statistics
    const totalQuizzesAttempted = quizAttempts.length;
    const totalCorrectAnswers = quizAttempts.reduce((sum, attempt) => sum + attempt.score, 0);
    const totalQuestionsAnswered = quizAttempts.reduce((sum, attempt) => sum + attempt.totalPoints, 0);
    const averageScore = totalQuestionsAnswered > 0 ? (totalCorrectAnswers / totalQuestionsAnswered) * 100 : 0;
    const totalTimeSpent = quizAttempts.reduce((sum, attempt) => sum + (attempt.timeSpent || 0), 0);

    // Get unique categories (quizzes) completed
    const uniqueQuizzes = new Set(quizAttempts.map(attempt => attempt.quizId));
    const categoriesCompleted = uniqueQuizzes.size;

    // Find best category
    const quizScores = new Map();
    quizAttempts.forEach(attempt => {
      const quizId = attempt.quizId;
      const percentage = attempt.totalPoints > 0 ? (attempt.score / attempt.totalPoints) * 100 : 0;
      
      if (!quizScores.has(quizId) || quizScores.get(quizId).percentage < percentage) {
        quizScores.set(quizId, {
          quizId,
          quizTitle: attempt.quiz.title,
          percentage,
        });
      }
    });

    let bestCategory = null;
    let bestCategoryAverage = 0;
    
    if (quizScores.size > 0) {
      const bestQuiz = Array.from(quizScores.values()).reduce((best, current) => 
        current.percentage > best.percentage ? current : best
      );
      bestCategory = bestQuiz.quizId;
      bestCategoryAverage = bestQuiz.percentage;
    }

    // Get last activity
    const lastActivity = quizAttempts.length > 0 
      ? quizAttempts[quizAttempts.length - 1].completedAt 
      : null;

    return NextResponse.json({
      success: true,
      totalQuizzesAttempted,
      totalCorrectAnswers,
      totalQuestionsAnswered,
      averageScore: Math.round(averageScore * 10) / 10,
      totalTimeSpent: Math.round(totalTimeSpent / 60), // Convert to minutes
      categoriesCompleted,
      bestCategory,
      bestCategoryAverage: Math.round(bestCategoryAverage * 10) / 10,
      lastActivity,
    });
  } catch (error) {
    console.error("Error fetching user stats:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch user statistics" },
      { status: 500 }
    );
  }
}
