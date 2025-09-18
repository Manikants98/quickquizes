import { NextRequest, NextResponse } from "next/server";
import { analyzeRequest } from "../lib/gemini";
import { AIMiddlewareConfig, RequestContext, MiddlewareResult } from "./types";
import { extractRequestContext, createErrorResponse } from "./utils";

// Constants
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
const MIN_REQUEST_INTERVAL = 1000; // 1 second between AI calls
const MAX_CACHE_SIZE = 1000; // Prevent memory bloat
const MAX_REQUEST_HISTORY = 10000; // Prevent unbounded growth
const CACHE_KEY_MAX_LENGTH = 100; // Limit cache key size

// Suspicious patterns compiled once
const SUSPICIOUS_PATTERNS = [
  /DROP\s+TABLE/i,
  /SELECT\s*\*\s*FROM/i,
  /\.\.\/\.\.\/\.\.\//,
  /<script[^>]*>/i,
  /eval\s*KATEX_INLINE_OPEN/i,
  /javascript:/i,
] as const;

// LRU Cache implementation
class LRUCache<T> {
  private cache = new Map<string, { data: T; timestamp: number }>();
  private accessOrder: string[] = [];

  constructor(private maxSize: number) {}

  get(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry || Date.now() - entry.timestamp > CACHE_DURATION) {
      this.cache.delete(key);
      return null;
    }

    // Move to end (most recently used)
    const index = this.accessOrder.indexOf(key);
    if (index > -1) {
      this.accessOrder.splice(index, 1);
    }
    this.accessOrder.push(key);

    return entry.data;
  }

  set(key: string, data: T): void {
    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize && !this.cache.has(key)) {
      const oldest = this.accessOrder.shift();
      if (oldest) this.cache.delete(oldest);
    }

    this.cache.set(key, { data, timestamp: Date.now() });

    const index = this.accessOrder.indexOf(key);
    if (index > -1) {
      this.accessOrder.splice(index, 1);
    }
    this.accessOrder.push(key);
  }

  clear(): void {
    this.cache.clear();
    this.accessOrder = [];
  }
}

// Rate limiter with automatic cleanup
class RateLimiter {
  private lastRequestTime = new Map<string, number>();
  private requestCount = new Map<string, number>();
  private cleanupInterval: NodeJS.Timeout;

  constructor(private maxEntries: number = MAX_REQUEST_HISTORY) {
    // Cleanup old entries every 5 minutes
    this.cleanupInterval = setInterval(() => this.cleanup(), 5 * 60 * 1000);
  }

  shouldAllowRequest(ip: string): boolean {
    const lastCall = this.lastRequestTime.get(ip);
    return !lastCall || Date.now() - lastCall > MIN_REQUEST_INTERVAL;
  }

  recordRequest(ip: string): void {
    this.lastRequestTime.set(ip, Date.now());
    const count = this.requestCount.get(ip) || 0;
    this.requestCount.set(ip, count + 1);

    // Prevent unbounded growth
    if (this.requestCount.size > this.maxEntries) {
      this.cleanup();
    }
  }

  getRequestCount(ip: string): number {
    return this.requestCount.get(ip) || 0;
  }

  private cleanup(): void {
    const now = Date.now();
    const staleThreshold = 60 * 60 * 1000; // 1 hour

    for (const [ip, time] of this.lastRequestTime.entries()) {
      if (now - time > staleThreshold) {
        this.lastRequestTime.delete(ip);
        this.requestCount.delete(ip);
      }
    }
  }

  destroy(): void {
    clearInterval(this.cleanupInterval);
  }
}

// Global instances
const cache = new LRUCache<any>(MAX_CACHE_SIZE);
const rateLimiter = new RateLimiter();

// Initialize configuration with defaults
export function createAIMiddlewareConfig(
  config: Partial<AIMiddlewareConfig> = {}
): AIMiddlewareConfig {
  return {
    enableAuth: true,
    enableRateLimit: true,
    enableErrorHandling: true,
    enableResponseTransform: true,
    ...config,
  } as AIMiddlewareConfig;
}

// Main processing function
export async function processAIMiddleware(
  request: NextRequest,
  config: AIMiddlewareConfig
): Promise<NextResponse | null> {
  const startTime = performance.now();

  try {
    const context = extractRequestContext(request);
    const cacheKey = generateCacheKey(context);

    // Check cache first
    const cached = cache.get(cacheKey);
    if (cached) {
      console.log("🚀 Using cached AI decision");
      return executeAction(cached, request, context);
    }

    // Rate limit AI calls
    if (!rateLimiter.shouldAllowRequest(context.ip)) {
      console.log("⏱️ AI call rate limited, using fallback logic");
      return fallbackLogic(context, request);
    }

    // Make AI call
    const analysis = await analyzeRequest(
      {
        context,
        config,
        requestHistory: rateLimiter.getRequestCount(context.ip),
      },
      buildAnalysisContext(config)
    );

    // Cache the result
    cache.set(cacheKey, analysis);
    rateLimiter.recordRequest(context.ip);

    const result = await executeAction(analysis, request, context);

    // Only log in development or if explicitly enabled
    if (process.env.NODE_ENV === "development") {
      logResult({
        success: true,
        analysis,
        executionTime: performance.now() - startTime,
      });
    }

    return result;
  } catch (error) {
    console.error("AI Middleware Error:", error);
    return handleError(error, request);
  }
}

// Optimized cache key generation
function generateCacheKey(context: RequestContext): string {
  const key = `${context.method}-${
    context.pathname
  }-${context.userAgent.substring(0, 20)}`;
  return key.length > CACHE_KEY_MAX_LENGTH
    ? key.substring(0, CACHE_KEY_MAX_LENGTH)
    : key;
}

// Optimized fallback logic with regex patterns
function fallbackLogic(
  context: RequestContext,
  request: NextRequest
): NextResponse | null {
  // Check URL and body for suspicious patterns
  const checkString = `${context.url} ${JSON.stringify(context.body || "")}`;

  const isSuspicious = SUSPICIOUS_PATTERNS.some((pattern) =>
    pattern.test(checkString)
  );

  if (isSuspicious) {
    return new NextResponse(
      JSON.stringify({
        error: "Request blocked by security rules",
        reason: "Suspicious pattern detected",
      }),
      {
        status: 403,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  console.log("✅ Fallback logic: Request allowed");
  return null;
}

// Simplified analysis context builder
function buildAnalysisContext(config: AIMiddlewareConfig): string {
  const features = [];

  if (config.enableAuth) features.push("AUTHENTICATION");
  if (config.enableRateLimit) features.push("RATE_LIMITING");
  if (config.enableErrorHandling) features.push("ERROR_HANDLING");
  if (config.enableResponseTransform) features.push("RESPONSE_TRANSFORM");

  if (config.customRules?.length) {
    features.push(`CUSTOM_RULES: ${config.customRules.join(", ")}`);
  }

  return features.join(" | ");
}

// Optimized action execution
async function executeAction(
  analysis: any,
  request: NextRequest,
  context: RequestContext
): Promise<NextResponse | null> {
  switch (analysis.action) {
    case "block":
      return new NextResponse(
        JSON.stringify({
          error: "Request blocked by AI middleware",
          reason: analysis.reasoning,
        }),
        {
          status: analysis.statusCode || 403,
          headers: { "Content-Type": "application/json" },
        }
      );

    case "redirect":
      return NextResponse.redirect(
        new URL(analysis.redirectUrl || "/", request.url)
      );

    case "transform":
      // Apply transformations inline if needed
      if (analysis.modifications?.headers) {
        for (const [key, value] of Object.entries(
          analysis.modifications.headers
        )) {
          request.headers.set(key, String(value));
        }
      }
      return null;

    case "error":
      return createErrorResponse(analysis.reasoning, 500);

    case "allow":
    default:
      return null;
  }
}

// Simplified error handling
function handleError(error: unknown, request: NextRequest): NextResponse {
  const message = error instanceof Error ? error.message : String(error);
  return createErrorResponse(`AI Middleware Error: ${message}`, 500);
}

// Lightweight logging
function logResult(result: MiddlewareResult): void {
  console.log("AI Middleware Result:", {
    timestamp: new Date().toISOString(),
    ...result,
  });
}

// Cleanup function for graceful shutdown
export function cleanupAIMiddleware(): void {
  rateLimiter.destroy();
  cache.clear();
}
