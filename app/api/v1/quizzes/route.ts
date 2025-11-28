import { Prisma, $Enums } from "@/lib/generated/prisma";
import { prisma } from "@/lib/prisma";
import { seedDatabase } from "@/lib/seed";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const isPublic = searchParams.get("isPublic");
    const page = parseInt(searchParams.get("page") || "1");
    const limit = parseInt(searchParams.get("limit") || "10");
    const includeCount = searchParams.get("includeCount") === "true";

    const skip = (page - 1) * limit;

    let total = 0;
    if (includeCount) {
      total = await prisma.quiz.count({
        where: {
          isPublic: isPublic ? isPublic === "true" : undefined,
        },
      });
    }

    const quizzes = await prisma.quiz.findMany({
      skip,
      take: limit,
      where: {
        isPublic: isPublic ? isPublic === "true" : undefined,
      },
      include: {
        createdBy: true,
        _count: {
          select: {
            quizQuestions: true,
            quizAttempts: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    return NextResponse.json({
      success: true,
      quizzes: quizzes.map((quiz) => ({
        id: quiz.id,
        title: quiz.title,
        description: quiz.description || "",
        category: quiz.category || "General",
        duration: quiz.timeLimit,
        totalQuestions: quiz._count.quizQuestions,
        difficulty: quiz.difficulty?.toLowerCase() || "medium",
        imageUrl: quiz.imageUrl || "",
        questions: [],
        timeLimit: quiz.timeLimit,
        questionCount: quiz._count.quizQuestions,
        isPublic: quiz.isPublic,
        attemptCount: quiz._count.quizAttempts,
        createdAt: quiz.createdAt,
        createdBy: quiz.createdBy?.name || "Unknown",
      })),
      total: includeCount ? total : undefined,
      page,
      limit,
      totalPages: includeCount ? Math.ceil(total / limit) : undefined,
    });
  } catch (error) {
    console.error("Error fetching quizzes:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      {
        success: false,
        error: "Failed to fetch quizzes",
        details: errorMessage,
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      title,
      description,
      category,
      difficulty,
      imageUrl,
      timeLimit,
      isPublic,
    } = body;

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

    const validDifficulties = ["EASY", "MEDIUM", "HARD"];
    let difficultyValue: $Enums.Difficulty = $Enums.Difficulty.MEDIUM;
    if (difficulty) {
      const upperDifficulty = difficulty.toUpperCase();
      if (!validDifficulties.includes(upperDifficulty)) {
        return NextResponse.json(
          { success: false, error: "Difficulty must be easy, medium, or hard" },
          { status: 400 }
        );
      }
      difficultyValue = upperDifficulty as $Enums.Difficulty;
    }

    let adminUser = await prisma.user.findFirst({
      where: { role: "ADMIN" },
    });

    if (!adminUser) {
      await seedDatabase();
      adminUser = await prisma.user.findFirst({
        where: { role: "ADMIN" },
      });

      if (!adminUser) {
        return NextResponse.json(
          {
            success: false,
            error: "No admin user found. Please seed the database.",
          },
          { status: 500 }
        );
      }
    }

    const quizData: any = {
      title: title.trim(),
      description: description ? description.trim() : "",
      difficulty: difficultyValue,
      timeLimit: timeLimit || 30,
      isPublic: isPublic !== false,
      createdById: adminUser.id,
    };

    if (category && category.trim().length > 0) {
      quizData.category = category.trim();
    }

    if (imageUrl && imageUrl.trim().length > 0) {
      quizData.imageUrl = imageUrl.trim();
    }

    const newQuiz = await prisma.quiz.create({
      data: quizData,
      include: {
        quizQuestions: {
          include: {
            question: true,
          },
          orderBy: {
            order: "asc",
          },
        },
        createdBy: true,
        _count: {
          select: {
            quizQuestions: true,
            quizAttempts: true,
          },
        },
      },
    });

    return NextResponse.json({
      success: true,
      quiz: {
        id: newQuiz.id,
        title: newQuiz.title,
        description: newQuiz.description || "",
        category: newQuiz.category || "General",
        duration: newQuiz.timeLimit,
        totalQuestions: newQuiz._count.quizQuestions,
        difficulty: newQuiz.difficulty?.toLowerCase() || "medium",
        imageUrl: newQuiz.imageUrl || "",
        questions: newQuiz.quizQuestions.map((qq) => ({
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
        timeLimit: newQuiz.timeLimit,
        questionCount: newQuiz._count.quizQuestions,
        attemptCount: newQuiz._count.quizAttempts,
        createdAt: newQuiz.createdAt,
        createdBy: newQuiz.createdBy.name,
      },
    });
  } catch (error) {
    console.error("Error creating quiz:", error);
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";

    if (errorMessage.includes("Unique constraint")) {
      return NextResponse.json(
        { success: false, error: "A quiz with this title already exists" },
        { status: 400 }
      );
    }

    if (errorMessage.includes("Foreign key constraint")) {
      return NextResponse.json(
        { success: false, error: "Invalid user or reference" },
        { status: 400 }
      );
    }

    return NextResponse.json(
      {
        success: false,
        error: "Failed to create quiz",
        details: errorMessage,
      },
      { status: 500 }
    );
  }
}
