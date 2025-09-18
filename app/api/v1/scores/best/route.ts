import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("userId");
    const categoryId = searchParams.get("categoryId");

    if (!userId || !categoryId) {
      return NextResponse.json(
        { success: false, error: "User ID and category ID are required" },
        { status: 400 }
      );
    }

    // Get best score for the user in the specific category
    const bestAttempt = await prisma.quizAttempt.findFirst({
      where: {
        userId: userId,
        quizId: categoryId,
        status: "COMPLETED",
      },
      include: {
        quiz: {
          select: {
            id: true,
            title: true,
          },
        },
      },
      orderBy: [
        {
          score: "desc",
        },
        {
          completedAt: "desc",
        },
      ],
    });

    if (!bestAttempt) {
      return NextResponse.json({
        success: true,
        bestScore: null,
      });
    }

    const bestScore = {
      id: bestAttempt.id,
      userId: bestAttempt.userId,
      categoryId: bestAttempt.quizId,
      categoryName: bestAttempt.quiz.title,
      score: bestAttempt.score,
      totalQuestions: bestAttempt.totalPoints,
      percentage: bestAttempt.totalPoints > 0 ? Math.round((bestAttempt.score / bestAttempt.totalPoints) * 100) : 0,
      timeSpent: Math.round((bestAttempt.timeSpent || 0) / 60), // Convert to minutes
      completedAt: bestAttempt.completedAt,
      createdAt: bestAttempt.createdAt,
    };

    return NextResponse.json({
      success: true,
      bestScore,
    });
  } catch (error) {
    console.error("Error fetching best score:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch best score" },
      { status: 500 }
    );
  }
}
