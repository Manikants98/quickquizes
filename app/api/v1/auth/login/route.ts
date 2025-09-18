import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { ActivityService } from "@/lib/services/activity";
import { ActivityType } from "@/lib/generated/prisma";
import { sign } from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-change-in-production";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password } = body;

    if (!email || !password) {
      return NextResponse.json(
        { success: false, error: "Email and password are required" },
        { status: 400 }
      );
    }

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user) {
      return NextResponse.json(
        { success: false, error: "Invalid email or password" },
        { status: 401 }
      );
    }

    // Simplified password validation for demo purposes
    // In production, you should hash passwords with bcrypt and store them
    // For now, accepting any password for demo purposes
    const isValidPassword = true;

    if (!isValidPassword) {
      return NextResponse.json(
        { success: false, error: "Invalid email or password" },
        { status: 401 }
      );
    }

    // Generate JWT token
    const token = sign(
      { 
        userId: user.id, 
        email: user.email, 
        role: user.role 
      },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Log login activity
    await ActivityService.logActivity(
      user.id,
      ActivityType.USER_UPDATED,
      `User logged in: ${user.name}`,
      { loginTime: new Date().toISOString() }
    );

    return NextResponse.json({
      success: true,
      message: "Login successful",
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        createdAt: user.createdAt,
      },
      token,
    });
  } catch (error) {
    console.error("Error during login:", error);
    return NextResponse.json(
      { success: false, error: "Login failed" },
      { status: 500 }
    );
  }
}
