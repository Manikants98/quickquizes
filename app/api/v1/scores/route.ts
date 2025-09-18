import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");
    const categoryId = searchParams.get("categoryId");

    if (!userId) {
      return NextResponse.json(
        { success: false, error: "User ID is required" },
        { status: 400 }
      );
    }

    // Build where clause
    const whereClause: any = {
      userId: userId,
      status: "COMPLETED",
    };

    if (categoryId) {
      whereClause.quizId = categoryId;
    }

    // Get quiz attempts (scores)
    const scores = await prisma.quizAttempt.findMany({
      where: whereClause,
      include: {
        quiz: {
          select: {
            id: true,
            title: true,
          },
        },
      },
      orderBy: {
        completedAt: "desc",
      },
    });

    const formattedScores = scores.map(attempt => ({
      id: attempt.id,
      userId: attempt.userId,
      categoryId: attempt.quizId,
      categoryName: attempt.quiz.title,
      score: attempt.score,
      totalQuestions: attempt.totalPoints,
      percentage: attempt.totalPoints > 0 ? Math.round((attempt.score / attempt.totalPoints) * 100) : 0,
      timeSpent: Math.round((attempt.timeSpent || 0) / 60), // Convert to minutes
      completedAt: attempt.completedAt,
      createdAt: attempt.createdAt,
    }));

    return NextResponse.json({
      success: true,
      scores: formattedScores,
    });
  } catch (error) {
    console.error("Error fetching scores:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch scores" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { userId, categoryId, score, totalQuestions, percentage, timeSpent } = body;

    if (!userId || !categoryId || score === undefined || !totalQuestions) {
      return NextResponse.json(
        { success: false, error: "Missing required fields" },
        { status: 400 }
      );
    }

    // Create a new quiz attempt record
    const newScore = await prisma.quizAttempt.create({
      data: {
        userId,
        quizId: categoryId,
        score,
        totalPoints: totalQuestions,
        timeSpent: timeSpent ? timeSpent * 60 : null, // Convert minutes to seconds
        status: "COMPLETED",
        completedAt: new Date(),
      },
      include: {
        quiz: {
          select: {
            id: true,
            title: true,
          },
        },
      },
    });

    return NextResponse.json({
      success: true,
      score: {
        id: newScore.id,
        userId: newScore.userId,
        categoryId: newScore.quizId,
        categoryName: newScore.quiz.title,
        score: newScore.score,
        totalQuestions: newScore.totalPoints,
        percentage: newScore.totalPoints > 0 ? Math.round((newScore.score / newScore.totalPoints) * 100) : 0,
        timeSpent: Math.round((newScore.timeSpent || 0) / 60),
        completedAt: newScore.completedAt,
        createdAt: newScore.createdAt,
      },
    });
  } catch (error) {
    console.error("Error saving score:", error);
    return NextResponse.json(
      { success: false, error: "Failed to save score" },
      { status: 500 }
    );
  }
}
