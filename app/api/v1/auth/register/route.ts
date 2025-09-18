import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { ActivityService } from "@/lib/services/activity";
import { ActivityType } from "@/lib/generated/prisma";
import { sign } from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-change-in-production";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, email, password } = body;

    if (!name || !email || !password) {
      return NextResponse.json(
        { success: false, error: "Name, email, and password are required" },
        { status: 400 }
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { success: false, error: "Invalid email format" },
        { status: 400 }
      );
    }

    // Validate password length
    if (password.length < 6) {
      return NextResponse.json(
        { success: false, error: "Password must be at least 6 characters long" },
        { status: 400 }
      );
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      return NextResponse.json(
        { success: false, error: "User with this email already exists" },
        { status: 400 }
      );
    }

    // Create new user
    // Note: In production, you should hash the password with bcrypt
    // For demo purposes, we're storing it as is (not recommended)
    const newUser = await prisma.user.create({
      data: {
        name: name.trim(),
        email: email.toLowerCase(),
        role: "USER",
      },
    });

    // Generate JWT token
    const token = sign(
      { 
        userId: newUser.id, 
        email: newUser.email, 
        role: newUser.role 
      },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    // Log user registration activity
    await ActivityService.logActivity(
      newUser.id,
      ActivityType.USER_REGISTERED,
      `New user registered: ${newUser.name}`,
      { 
        userId: newUser.id, 
        role: newUser.role,
        registrationTime: new Date().toISOString()
      }
    );

    return NextResponse.json({
      success: true,
      message: "Registration successful",
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
        createdAt: newUser.createdAt,
      },
      token,
    });
  } catch (error) {
    console.error("Error during registration:", error);
    return NextResponse.json(
      { success: false, error: "Registration failed" },
      { status: 500 }
    );
  }
}
