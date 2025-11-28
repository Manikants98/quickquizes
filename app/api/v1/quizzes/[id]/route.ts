import { NextRequest, NextResponse } from "next/server";
import { ActivityService } from "@/lib/services/activity";
import { ActivityType } from "@/lib/generated/prisma";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { prisma } = await import("@/lib/prisma");

    const { id: quizId } = await params;

    if (!quizId || typeof quizId !== "string" || quizId.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Invalid quiz ID" },
        { status: 400 }
      );
    }

    const quiz = await prisma.quiz.findUnique({
      where: {
        id: quizId.trim(),
      },
      include: {
        createdBy: true,
        quizQuestions: {
          include: {
            question: true,
          },
          orderBy: {
            order: "asc",
          },
        },
        _count: {
          select: {
            quizQuestions: true,
            quizAttempts: true,
          },
        },
      },
    });

    if (!quiz) {
      return NextResponse.json(
        { success: false, error: "Quiz not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      quiz: {
        id: quiz.id,
        title: quiz.title,
        description: quiz.description || "",
        category: quiz.category || "General",
        duration: quiz.timeLimit,
        totalQuestions: quiz._count.quizQuestions,
        difficulty: quiz.difficulty?.toLowerCase() || "medium",
        imageUrl: quiz.imageUrl || "",
        questions: quiz.quizQuestions.map((qq) => ({
          id: qq.question.id,
          question: qq.question.question,
          options: [
            qq.question.option1,
            qq.question.option2,
            qq.question.option3,
            qq.question.option4,
          ],
          correctAnswerIndex: qq.question.correctAnswer - 1,
          explanation: qq.question.explanation || "",
        })),
        timeLimit: quiz.timeLimit,
        questionCount: quiz._count.quizQuestions,
        isPublic: quiz.isPublic,
        attemptCount: quiz._count.quizAttempts,
        createdAt: quiz.createdAt,
        createdBy: quiz.createdBy.name,
      },
    });
  } catch (error) {
    console.error("Error fetching quiz:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch quiz" },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { prisma } = await import("@/lib/prisma");
    const body = await request.json();
    const { title, description, timeLimit, isPublic } = body;

    const { id: quizId } = await params;

    if (!quizId || typeof quizId !== "string" || quizId.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Invalid quiz ID" },
        { status: 400 }
      );
    }

    if (!title || typeof title !== "string" || title.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Title is required" },
        { status: 400 }
      );
    }

    if (
      timeLimit !== undefined &&
      (typeof timeLimit !== "number" || timeLimit < 1 || timeLimit > 300)
    ) {
      return NextResponse.json(
        {
          success: false,
          error: "Time limit must be between 1 and 300 minutes",
        },
        { status: 400 }
      );
    }

    const { category, difficulty, imageUrl } = body;

    const updateData = {
      title: title.trim(),
      description: description ? description.trim() : "",
      category: category || null,
      difficulty: difficulty ? difficulty.toUpperCase() : undefined,
      imageUrl: imageUrl || null,
      timeLimit: timeLimit || 30,
      isPublic: isPublic !== false,
    };

    const updatedQuiz = await prisma.quiz.update({
      where: { id: quizId.trim() },
      data: updateData,
      include: {
        createdBy: true,
        _count: {
          select: {
            quizQuestions: true,
            quizAttempts: true,
          },
        },
      },
    });

    await ActivityService.logActivity(
      updatedQuiz.createdById,
      ActivityType.QUIZ_UPDATED,
      `Quiz updated: ${updatedQuiz.title}`,
      { quizId: updatedQuiz.id }
    );

    return NextResponse.json({
      success: true,
      quiz: {
        id: updatedQuiz.id,
        title: updatedQuiz.title,
        description: updatedQuiz.description || "",
        category: updatedQuiz.category || "General",
        duration: updatedQuiz.timeLimit,
        totalQuestions: updatedQuiz._count.quizQuestions,
        difficulty: updatedQuiz.difficulty?.toLowerCase() || "medium",
        imageUrl: updatedQuiz.imageUrl || "",
        timeLimit: updatedQuiz.timeLimit,
        questionCount: updatedQuiz._count.quizQuestions,
        isPublic: updatedQuiz.isPublic,
        attemptCount: updatedQuiz._count.quizAttempts,
        createdAt: updatedQuiz.createdAt,
        createdBy: updatedQuiz.createdBy.name,
      },
    });
  } catch (error) {
    console.error("Error updating quiz:", error);
    return NextResponse.json(
      { success: false, error: "Failed to update quiz" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { prisma } = await import("@/lib/prisma");

    const { id: quizId } = await params;

    if (!quizId || typeof quizId !== "string" || quizId.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Invalid quiz ID" },
        { status: 400 }
      );
    }

    const existingQuiz = await prisma.quiz.findUnique({
      where: { id: quizId.trim() },
      include: { createdBy: true },
    });

    if (!existingQuiz) {
      return NextResponse.json(
        { success: false, error: "Quiz not found" },
        { status: 404 }
      );
    }

    const deletedQuiz = await prisma.quiz.delete({
      where: { id: quizId.trim() },
      include: {
        createdBy: true,
      },
    });

    await ActivityService.logActivity(
      deletedQuiz.createdById,
      ActivityType.QUIZ_DELETED,
      `Quiz deleted: ${deletedQuiz.title}`,
      { quizId: deletedQuiz.id }
    );

    return NextResponse.json({
      success: true,
      message: "Quiz deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting quiz:", error);
    return NextResponse.json(
      { success: false, error: "Failed to delete quiz" },
      { status: 500 }
    );
  }
}
