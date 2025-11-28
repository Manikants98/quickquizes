import { NextRequest, NextResponse } from "next/server";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { prisma } = await import("@/lib/prisma");

    const { id: quizId } = await params;
    const { searchParams } = new URL(request.url);
    const page = Math.max(1, parseInt(searchParams.get("page") || "1"));
    const limit = Math.min(
      100,
      Math.max(1, parseInt(searchParams.get("limit") || "10"))
    );

    if (!quizId || typeof quizId !== "string" || quizId.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Invalid quiz ID" },
        { status: 400 }
      );
    }

    const quiz = await prisma.quiz.findUnique({
      where: { id: quizId.trim() },
      select: { id: true },
    });

    if (!quiz) {
      return NextResponse.json(
        { success: false, error: "Quiz not found" },
        { status: 404 }
      );
    }

    const skip = (page - 1) * limit;

    const total = await prisma.quizQuestion.count({
      where: { quizId: quizId.trim() },
    });

    const questions = await prisma.quizQuestion.findMany({
      skip,
      take: limit,
      where: {
        quizId: quizId.trim(),
      },
      include: {
        question: true,
      },
      orderBy: {
        order: "asc",
      },
    });

    return NextResponse.json({
      success: true,
      questions: questions.map((qq) => ({
        id: qq.question.id,
        question: qq.question.question,
        options: [
          qq.question.option1,
          qq.question.option2,
          qq.question.option3,
          qq.question.option4,
        ],
        correctAnswerIndex: qq.question.correctAnswer - 1,
        correctAnswer: qq.question.correctAnswer - 1,
        difficulty: qq.question.difficulty.toLowerCase(),
        explanation: qq.question.explanation || "",
        order: qq.order,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error("Error fetching quiz questions:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch quiz questions" },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { prisma } = await import("@/lib/prisma");
    const body = await request.json();
    const { question, options, correctAnswer, difficulty, explanation } = body;

    const { id: quizId } = await params;

    if (!quizId || typeof quizId !== "string" || quizId.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: "Invalid quiz ID" },
        { status: 400 }
      );
    }

    if (
      !question ||
      typeof question !== "string" ||
      question.trim().length === 0
    ) {
      return NextResponse.json(
        { success: false, error: "Question text is required" },
        { status: 400 }
      );
    }

    if (!Array.isArray(options) || options.length !== 4) {
      return NextResponse.json(
        { success: false, error: "Exactly 4 options are required" },
        { status: 400 }
      );
    }

    for (let i = 0; i < options.length; i++) {
      if (
        !options[i] ||
        typeof options[i] !== "string" ||
        options[i].trim().length === 0
      ) {
        return NextResponse.json(
          { success: false, error: `Option ${i + 1} is required` },
          { status: 400 }
        );
      }
    }

    if (
      typeof correctAnswer !== "number" ||
      correctAnswer < 0 ||
      correctAnswer > 3
    ) {
      return NextResponse.json(
        { success: false, error: "Correct answer must be between 0 and 3" },
        { status: 400 }
      );
    }

    const validDifficulties = ["easy", "medium", "hard"];
    if (!difficulty || !validDifficulties.includes(difficulty.toLowerCase())) {
      return NextResponse.json(
        { success: false, error: "Difficulty must be easy, medium, or hard" },
        { status: 400 }
      );
    }

    const quiz = await prisma.quiz.findUnique({
      where: { id: quizId.trim() },
      select: { id: true },
    });

    if (!quiz) {
      return NextResponse.json(
        { success: false, error: "Quiz not found" },
        { status: 404 }
      );
    }

    const { seedDatabase } = await import("@/lib/seed");
    let adminUser = await prisma.user.findFirst({
      where: { role: "ADMIN" },
    });

    if (!adminUser) {
      await seedDatabase();
      adminUser = await prisma.user.findFirst({
        where: { role: "ADMIN" },
      });
    }

    const lastQuestion = await prisma.quizQuestion.findFirst({
      where: { quizId: quizId.trim() },
      orderBy: { order: "desc" },
    });
    const nextOrder = (lastQuestion?.order || 0) + 1;

    const newQuestion = await prisma.question.create({
      data: {
        question: question.trim(),
        option1: options[0].trim(),
        option2: options[1].trim(),
        option3: options[2].trim(),
        option4: options[3].trim(),
        correctAnswer: correctAnswer + 1,
        difficulty: difficulty.toUpperCase(),
        explanation: explanation ? explanation.trim() : "",
        createdById: adminUser!.id,
      },
    });

    await prisma.quizQuestion.create({
      data: {
        quizId: quizId.trim(),
        questionId: newQuestion.id,
        order: nextOrder,
        points: 1,
      },
    });

    return NextResponse.json({
      success: true,
      question: {
        id: newQuestion.id,
        question: newQuestion.question,
        options: [
          newQuestion.option1,
          newQuestion.option2,
          newQuestion.option3,
          newQuestion.option4,
        ],
        correctAnswerIndex: newQuestion.correctAnswer - 1,
        correctAnswer: newQuestion.correctAnswer - 1,
        difficulty: newQuestion.difficulty.toLowerCase(),
        explanation: newQuestion.explanation || "",
        order: nextOrder,
      },
    });
  } catch (error) {
    console.error("Error creating question:", error);
    return NextResponse.json(
      { success: false, error: "Failed to create question" },
      { status: 500 }
    );
  }
}
