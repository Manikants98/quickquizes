import { NextRequest } from "next/server";
import {
  createAIMiddlewareConfig,
  processAIMiddleware,
} from "./middleware/ai-middleware";
import { isPublicPath } from "./middleware/utils";

const aiConfig = createAIMiddlewareConfig({
  enableAuth: true,
  enableRateLimit: true,
  enableErrorHandling: true,
  enableResponseTransform: true,
  customRules: [
    "Block suspicious bot traffic",
    "Allow authenticated users to protected routes",
    "Transform response format for mobile clients",
    "Rate limit based on user tier",
  ],
});

export async function middleware(request: NextRequest) {
  if (isPublicPath(request.nextUrl.pathname)) {
    return;
  }

  const result = await processAIMiddleware(request, aiConfig);
  if (result) {
    return result;
  }
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    "/((?!_next/static|_next/image|favicon.ico).*)",
  ],
};
