import { NextRequest, NextResponse } from "next/server";
import moment from "moment";

export async function GET(request: NextRequest) {
  try {
    const { prisma } = await import("@/lib/prisma");

    // Get basic counts
    const [totalUsers, totalQuizzes, totalQuestions, totalAttempts] = await Promise.all([
      prisma.user.count(),
      prisma.quiz.count({ where: { isActive: true } }),
      prisma.question.count({ where: { isActive: true } }),
      prisma.quizAttempt.count(),
    ]);

    // Get recent activities (last 10)
    const recentActivities = await prisma.activityLog.findMany({
      take: 10,
      orderBy: { createdAt: "desc" },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    // Get activity data for the last 7 days
    const sevenDaysAgo = moment().subtract(7, "days").startOf("day").toDate();
    const activityData = [];
    
    for (let i = 6; i >= 0; i--) {
      const date = moment().subtract(i, "days").format("YYYY-MM-DD");
      const dayStart = moment().subtract(i, "days").startOf("day").toDate();
      const dayEnd = moment().subtract(i, "days").endOf("day").toDate();
      
      const activities = await prisma.activityLog.count({
        where: {
          createdAt: {
            gte: dayStart,
            lte: dayEnd,
          },
        },
      });
      
      activityData.push({
        date,
        activities,
      });
    }

    // Get questions with difficulty breakdown
    const questions = await prisma.question.findMany({
      where: { isActive: true },
      select: {
        id: true,
        difficulty: true,
      },
    });

    // Get quizzes with counts
    const quizzes = await prisma.quiz.findMany({
      where: { isActive: true },
      select: {
        id: true,
        title: true,
        _count: {
          select: {
            quizQuestions: true,
            quizAttempts: true,
          },
        },
      },
      take: 10,
      orderBy: { createdAt: "desc" },
    });

    // Calculate performance metrics
    const completedAttempts = await prisma.quizAttempt.count({
      where: { completedAt: { not: null } },
    });
    
    const avgScoreResult = await prisma.quizAttempt.aggregate({
      _avg: { score: true },
      where: { completedAt: { not: null } },
    });

    const completionRate = totalAttempts > 0 ? (completedAttempts / totalAttempts) * 100 : 0;
    const avgScore = avgScoreResult._avg?.score || 0;

    // Format response data
    const dashboardData = {
      // Basic stats
      stats: {
        totalUsers,
        totalQuizzes,
        totalQuestions,
        totalAttempts,
      },
      
      // Recent activities formatted for display
      recentActivities: recentActivities.map(activity => ({
        id: activity.id,
        type: activity.type,
        title: activity.title,
        time: activity.createdAt,
        user: activity.user,
        metadata: activity.metadata,
      })),
      
      // Activity chart data
      activityData,
      
      // Questions data for difficulty chart
      questions: questions.map(q => ({
        id: q.id,
        difficulty: q.difficulty.toLowerCase(),
      })),
      
      // Quizzes data for stats chart
      quizzes: quizzes.map(quiz => ({
        id: quiz.id,
        title: quiz.title,
        _count: {
          questions: quiz._count.quizQuestions,
          quizAttempts: quiz._count.quizAttempts,
        },
      })),
      
      // Performance metrics
      performanceMetrics: {
        avgScore: Math.round(avgScore),
        completionRate: Math.round(completionRate),
        userRetention: totalUsers > 1 ? Math.round((totalUsers - 1) / totalUsers * 100) : 0,
        platformActivity: recentActivities.length,
      },
    };

    return NextResponse.json({
      success: true,
      data: dashboardData,
    });
  } catch (error) {
    console.error("Error fetching dashboard data:", error);
    return NextResponse.json(
      { success: false, error: "Failed to fetch dashboard data" },
      { status: 500 }
    );
  }
}
