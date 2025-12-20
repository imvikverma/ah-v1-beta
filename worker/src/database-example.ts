/**
 * Example: How to implement database access in Cloudflare Worker using D1
 * 
 * This is a reference implementation showing how database would work.
 * To use this, you need to:
 * 1. Create a D1 database: wrangler d1 create aurum-harmony-db
 * 2. Add D1 binding to wrangler.toml
 * 3. Migrate schema and data
 * 4. Replace the TODO handlers in index.ts with these implementations
 */

// Example: Login with D1 database
export async function loginWithDatabase(
  request: Request,
  env: { DB: D1Database }
): Promise<Response> {
  try {
    const body: any = await request.json();
    const { email, phone, password } = body;

    if (!password) {
      return Response.json(
        { error: 'Password is required' },
        { status: 400, headers: corsHeaders }
      );
    }

    if (!email && !phone) {
      return Response.json(
        { error: 'Email or phone is required' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Query user from D1 database
    let user: any;
    if (email) {
      user = await env.DB.prepare(
        "SELECT * FROM users WHERE email = ? AND is_active = 1"
      ).bind(email).first();
    } else {
      user = await env.DB.prepare(
        "SELECT * FROM users WHERE phone = ? AND is_active = 1"
      ).bind(phone).first();
    }

    if (!user) {
      return Response.json(
        { error: 'Invalid credentials' },
        { status: 401, headers: corsHeaders }
      );
    }

    // Verify password (you'd need to implement bcrypt or similar)
    // For now, this is a placeholder
    const isValid = await verifyPassword(password, user.password_hash);
    if (!isValid) {
      return Response.json(
        { error: 'Invalid credentials' },
        { status: 401, headers: corsHeaders }
      );
    }

    // Create session token
    const sessionToken = generateSessionToken(user.id);
    
    // Store session in database
    await env.DB.prepare(
      "INSERT INTO sessions (user_id, token, created_at, expires_at) VALUES (?, ?, ?, ?)"
    ).bind(
      user.id,
      sessionToken,
      new Date().toISOString(),
      new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() // 7 days
    ).run();

    return Response.json(
      {
        token: sessionToken,
        user: {
          id: user.id,
          email: user.email,
          phone: user.phone,
          user_code: user.user_code,
          is_admin: user.is_admin,
        },
      },
      { status: 200, headers: corsHeaders }
    );
  } catch (error: any) {
    return Response.json(
      { error: 'Internal server error', details: error.message },
      { status: 500, headers: corsHeaders }
    );
  }
}

// Example: Get user info with D1
export async function getUserInfo(
  request: Request,
  env: { DB: D1Database }
): Promise<Response> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) {
    return Response.json(
      { error: 'Authorization required' },
      { status: 401, headers: corsHeaders }
    );
  }

  const token = authHeader.replace('Bearer ', '');
  
  // Verify session token
  const session = await env.DB.prepare(
    "SELECT * FROM sessions WHERE token = ? AND expires_at > ?"
  ).bind(token, new Date().toISOString()).first();

  if (!session) {
    return Response.json(
      { error: 'Invalid or expired token' },
      { status: 401, headers: corsHeaders }
    );
  }

  // Get user
  const user = await env.DB.prepare(
    "SELECT id, email, phone, user_code, is_admin, is_active, created_at FROM users WHERE id = ?"
  ).bind(session.user_id).first();

  if (!user) {
    return Response.json(
      { error: 'User not found' },
      { status: 404, headers: corsHeaders }
    );
  }

  return Response.json(
    { user },
    { status: 200, headers: corsHeaders }
  );
}

// Example: Register new user with D1
export async function registerUser(
  request: Request,
  env: { DB: D1Database }
): Promise<Response> {
  try {
    const body: any = await request.json();
    const { email, password, phone } = body;

    if (!email) {
      return Response.json(
        { error: 'Email is required' },
        { status: 400, headers: corsHeaders }
      );
    }

    if (!password || password.length < 6) {
      return Response.json(
        { error: 'Password must be at least 6 characters' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Check if user already exists
    const existing = await env.DB.prepare(
      "SELECT id FROM users WHERE email = ? OR phone = ?"
    ).bind(email, phone || '').first();

    if (existing) {
      return Response.json(
        { error: 'User already exists' },
        { status: 409, headers: corsHeaders }
      );
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Generate user code
    const userCode = generateUserCode();

    // Insert user
    const result = await env.DB.prepare(
      `INSERT INTO users (email, phone, password_hash, user_code, is_admin, is_active, created_at, updated_at)
       VALUES (?, ?, ?, ?, 0, 1, ?, ?)`
    ).bind(
      email,
      phone || null,
      passwordHash,
      userCode,
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    return Response.json(
      {
        success: true,
        user: {
          id: result.meta.last_row_id,
          email,
          phone,
          user_code: userCode,
        },
      },
      { status: 201, headers: corsHeaders }
    );
  } catch (error: any) {
    return Response.json(
      { error: 'Internal server error', details: error.message },
      { status: 500, headers: corsHeaders }
    );
  }
}

// Helper functions (you'd need to implement these)

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  // Use bcrypt or similar
  // For Workers, you might need to use Web Crypto API or a library
  // This is a placeholder
  return false; // Implement actual verification
}

async function hashPassword(password: string): Promise<string> {
  // Use bcrypt or similar
  // This is a placeholder
  return ''; // Implement actual hashing
}

function generateSessionToken(userId: number): string {
  // Generate JWT or random token
  // This is a placeholder
  return `token_${userId}_${Date.now()}`;
}

function generateUserCode(): string {
  // Generate unique user code (e.g., "user001")
  // This is a placeholder
  return `user${Math.random().toString(36).substr(2, 9)}`;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
};
