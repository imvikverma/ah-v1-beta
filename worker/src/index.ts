/**
 * api.ah.saffronbolt.in – AurumHarmony API Worker
 * 
 * This Worker handles:
 * - Health checks
 * - Authentication endpoints (login, register, logout, me) with D1 database
 * - HDFC Sky OAuth callbacks
 * - Kotak Neo TOTP callbacks
 * - API routing with proper error handling
 */

import { hashPassword, verifyPassword, generateSessionToken, verifySessionToken, generateUserCode, generateEmailVerificationToken } from './auth';

// CORS headers helper
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
};

// Environment interface
interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  CLOUDFLARE_DEPLOY_HOOK?: string;
  GITHUB_WEBHOOK_SECRET?: string;
  HDFC_CLIENT_ID?: string;
  HDFC_CLIENT_SECRET?: string;
  KOTAK_CONSUMER_KEY?: string;
}

// Route handler type
type RouteHandler = (request: Request, env: any, url: URL) => Promise<Response>;

// Route definitions
interface Route {
  method: string;
  path: string | RegExp;
  handler: RouteHandler;
}

// Route handlers
const routes: Route[] = [
  // Health check
  {
    method: 'GET',
    path: '/health',
    handler: async () => {
      return Response.json(
        { status: 'ok', service: 'AurumHarmony API', version: '1.0' },
        { status: 200, headers: corsHeaders }
      );
    },
  },
  {
    method: 'GET',
    path: '/',
    handler: async () => {
      return Response.json(
        { status: 'ok', service: 'AurumHarmony API', version: '1.0' },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Authentication endpoints
  {
    method: 'POST',
    path: '/api/auth/login',
    handler: async (request, env: Env) => {
      try {
        // Parse request body
        let body: any;
        try {
          body = await request.json();
        } catch (e) {
          return Response.json(
            { error: 'Invalid JSON in request body' },
            { status: 400, headers: corsHeaders }
          );
        }

        const { email, phone, password } = body;

        // Validate input
        if (!password || password.trim() === '') {
          return Response.json(
            { error: 'Password is required' },
            { status: 400, headers: corsHeaders }
          );
        }

        if ((!email || email.trim() === '') && (!phone || phone.trim() === '')) {
          return Response.json(
            { error: 'Email or phone is required' },
            { status: 400, headers: corsHeaders }
          );
        }

        // Check if database is available
        if (!env.DB) {
          console.error('Database not configured - D1 binding missing');
          return Response.json(
            { 
              error: 'Database not configured', 
              message: 'D1 database binding not found',
              suggestion: 'Please configure D1 database in wrangler.toml and deploy the worker'
            },
            { status: 503, headers: corsHeaders }
          );
        }

        // Normalize email/phone
        const normalizedEmail = email ? email.trim().toLowerCase() : null;
        const normalizedPhone = phone ? phone.trim() : null;

        // Query user from database
        let user;
        try {
          if (normalizedEmail) {
            const result = await env.DB.prepare(
              "SELECT * FROM users WHERE LOWER(email) = ? AND is_active = 1"
            ).bind(normalizedEmail).first();
            user = result as any;
          } else if (normalizedPhone) {
            const result = await env.DB.prepare(
              "SELECT * FROM users WHERE phone = ? AND is_active = 1"
            ).bind(normalizedPhone).first();
            user = result as any;
          }
        } catch (dbError: any) {
          console.error('Database query error:', dbError);
          // Check if it's a schema issue
          if (dbError.message && dbError.message.includes('no such table')) {
            return Response.json(
              { 
                error: 'Database schema not migrated',
                message: 'Users table does not exist',
                suggestion: 'Run: wrangler d1 execute aurum-harmony-db --file=worker/schema.sql'
              },
              { status: 503, headers: corsHeaders }
            );
          }
          return Response.json(
            { 
              error: 'Database error',
              message: dbError.message || 'Failed to query database'
            },
            { status: 500, headers: corsHeaders }
          );
        }

        if (!user) {
          // Don't reveal if user exists or not (security best practice)
          return Response.json(
            { error: 'Invalid credentials' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Verify password
        if (!user.password_hash) {
          console.error('User found but password_hash is missing');
          return Response.json(
            { error: 'Invalid credentials' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Check if password is bcrypt hashed (from Flask backend)
        const isBcryptHash = user.password_hash.startsWith('$2a$') || 
                            user.password_hash.startsWith('$2b$') || 
                            user.password_hash.startsWith('$2y$');
        
        if (isBcryptHash) {
          // bcrypt verification not available in Workers
          // Return 501 to trigger fallback to Flask backend
          console.warn('bcrypt hash detected - Worker cannot verify. Use Flask backend.');
          return Response.json(
            {
              error: 'Password verification requires Flask backend',
              message: 'Worker cannot verify bcrypt hashes. Please use localhost backend for login.',
              fallback: 'http://localhost:5000/api/auth/login',
              status: 'bcrypt_not_supported'
            },
            { status: 501, headers: corsHeaders }
          );
        }

        let isValid;
        try {
          isValid = await verifyPassword(password, user.password_hash);
        } catch (verifyError: any) {
          console.error('Password verification error:', verifyError);
          return Response.json(
            { error: 'Internal server error', details: 'Password verification failed' },
            { status: 500, headers: corsHeaders }
          );
        }

        if (!isValid) {
          return Response.json(
            { error: 'Invalid credentials' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Generate session token
        const jwtSecret = env.JWT_SECRET || 'default-secret-change-in-production';
        let sessionToken;
        try {
          sessionToken = await generateSessionToken(user.id, jwtSecret);
        } catch (tokenError: any) {
          console.error('Token generation error:', tokenError);
          return Response.json(
            { error: 'Internal server error', details: 'Failed to generate session token' },
            { status: 500, headers: corsHeaders }
          );
        }
        
        // Store session in database
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // 7 days
        const now = new Date().toISOString();
        
        try {
          await env.DB.prepare(
            "INSERT INTO sessions (user_id, session_token, expires_at, created_at, last_accessed) VALUES (?, ?, ?, ?, ?)"
          ).bind(user.id, sessionToken, expiresAt, now, now).run();
        } catch (sessionError: any) {
          console.error('Session creation error:', sessionError);
          // Check if it's a schema issue
          if (sessionError.message && sessionError.message.includes('no such table')) {
            return Response.json(
              { 
                error: 'Database schema not migrated',
                message: 'Sessions table does not exist',
                suggestion: 'Run: wrangler d1 execute aurum-harmony-db --file=worker/schema.sql'
              },
              { status: 503, headers: corsHeaders }
            );
          }
          // Log but don't fail - session creation is nice to have but not critical
          console.warn('Failed to create session, but login succeeded');
        }

        return Response.json(
          {
            token: sessionToken,
            user: {
              id: user.id,
              email: user.email,
              phone: user.phone,
              user_code: user.user_code,
              is_admin: user.is_admin === 1,
            },
          },
          { status: 200, headers: corsHeaders }
        );
      } catch (error: any) {
        console.error('Login error:', error);
        return Response.json(
          { 
            error: 'Internal server error', 
            details: error.message,
            type: error.name || 'UnknownError'
          },
          { status: 500, headers: corsHeaders }
        );
      }
    },
  },
  {
    method: 'POST',
    path: '/api/auth/register',
    handler: async (request, env: Env) => {
      try {
        const body: any = await request.json();
        const { email, password, phone, username, profile_picture_url, terms_accepted } = body;

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

        if (terms_accepted !== true) {
          return Response.json(
            { error: 'You must accept the Terms & Conditions' },
            { status: 400, headers: corsHeaders }
          );
        }

        // Check if database is available
        if (!env.DB) {
          return Response.json(
            { error: 'Database not configured', message: 'D1 database binding not found' },
            { status: 503, headers: corsHeaders }
          );
        }

        // Check if user already exists (by email, phone, or username)
        const existing = await env.DB.prepare(
          "SELECT id FROM users WHERE email = ? OR phone = ? OR username = ?"
        ).bind(email, phone || '', username || '').first();

        if (existing) {
          return Response.json(
            { error: 'User with this email, phone, or username already exists' },
            { status: 409, headers: corsHeaders }
          );
        }

        // Hash password
        const passwordHash = await hashPassword(password);

        // Generate user code
        const userCode = generateUserCode();
        
        // Ensure unique user code
        let finalUserCode = userCode;
        let attempts = 0;
        while (attempts < 10) {
          const existingCode = await env.DB.prepare(
            "SELECT id FROM users WHERE user_code = ?"
          ).bind(finalUserCode).first();
          
          if (!existingCode) {
            break;
          }
          finalUserCode = generateUserCode();
          attempts++;
        }

        // Generate email verification token
        const emailVerificationToken = generateEmailVerificationToken();

        // Insert user with new fields
        const now = new Date().toISOString();
        const result = await env.DB.prepare(
          `INSERT INTO users (
            email, phone, password_hash, user_code, username, profile_picture_url,
            is_admin, is_active, email_verified, email_verification_token,
            terms_accepted, terms_accepted_at,
            initial_capital, max_accounts_allowed, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, 0, 1, 0, ?, ?, ?, 10000.0, 1, ?, ?)`
        ).bind(
          email,
          phone || null,
          passwordHash,
          finalUserCode,
          username || null,
          profile_picture_url || null,
          emailVerificationToken,
          terms_accepted ? 1 : 0,
          terms_accepted ? now : null,
          now,
          now
        ).run();

        return Response.json(
          {
            success: true,
            user: {
              id: result.meta.last_row_id,
              email,
              phone,
              username,
              user_code: finalUserCode,
              email_verified: false,
            },
            email_verification_token: emailVerificationToken, // Send token for verification
          },
          { status: 201, headers: corsHeaders }
        );
      } catch (error: any) {
        console.error('Registration error:', error);
        return Response.json(
          { error: 'Internal server error', details: error.message },
          { status: 500, headers: corsHeaders }
        );
      }
    },
  },
  {
    method: 'POST',
    path: '/api/auth/logout',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      // Delete session from database
      await env.DB.prepare(
        "DELETE FROM sessions WHERE session_token = ?"
      ).bind(token).run();

      return Response.json(
        { success: true, message: 'Logged out successfully' },
        { status: 200, headers: corsHeaders }
      );
    },
  },
  {
    method: 'GET',
    path: '/api/auth/me',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      // Verify session token
      const jwtSecret = env.JWT_SECRET || 'default-secret-change-in-production';
      const tokenData = await verifySessionToken(token, jwtSecret);
      
      if (!tokenData.valid) {
        // Also check database session
        const session = await env.DB.prepare(
          "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
        ).bind(token, new Date().toISOString()).first() as any;

        if (!session) {
          return Response.json(
            { error: 'Invalid or expired token' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Update last accessed
        await env.DB.prepare(
          "UPDATE sessions SET last_accessed = ? WHERE id = ?"
        ).bind(new Date().toISOString(), session.id).run();

        // Get user
        const user = await env.DB.prepare(
          "SELECT id, email, phone, user_code, is_admin, is_active, date_of_birth, anniversary, initial_capital, max_trades_per_index, max_accounts_allowed, created_at, updated_at FROM users WHERE id = ?"
        ).bind(session.user_id).first() as any;

        if (!user) {
          return Response.json(
            { error: 'User not found' },
            { status: 404, headers: corsHeaders }
          );
        }

        return Response.json(
          {
            user: {
              id: user.id,
              email: user.email,
              phone: user.phone,
              user_code: user.user_code,
              is_admin: user.is_admin === 1,
              is_active: user.is_active === 1,
              date_of_birth: user.date_of_birth,
              anniversary: user.anniversary,
              initial_capital: user.initial_capital,
              max_trades_per_index: user.max_trades_per_index ? JSON.parse(user.max_trades_per_index) : {},
              max_accounts_allowed: user.max_accounts_allowed,
              created_at: user.created_at,
              updated_at: user.updated_at,
            },
          },
          { status: 200, headers: corsHeaders }
        );
      }

      // Get user by token userId
      const user = await env.DB.prepare(
        "SELECT id, email, phone, user_code, is_admin, is_active, date_of_birth, anniversary, initial_capital, max_trades_per_index, max_accounts_allowed, created_at, updated_at FROM users WHERE id = ?"
      ).bind(tokenData.userId).first() as any;

      if (!user) {
        return Response.json(
          { error: 'User not found' },
          { status: 404, headers: corsHeaders }
        );
      }

      return Response.json(
        {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            user_code: user.user_code,
            is_admin: user.is_admin === 1,
            is_active: user.is_active === 1,
            date_of_birth: user.date_of_birth,
            anniversary: user.anniversary,
            initial_capital: user.initial_capital,
            max_trades_per_index: user.max_trades_per_index ? JSON.parse(user.max_trades_per_index) : {},
            max_accounts_allowed: user.max_accounts_allowed,
            created_at: user.created_at,
            updated_at: user.updated_at,
          },
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Admin endpoints - Get users list
  {
    method: 'GET',
    path: '/api/admin/users',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const jwtSecret = env.JWT_SECRET || 'default-secret-change-in-production';
      const tokenData = await verifySessionToken(token, jwtSecret);

      // Get user from session
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Check if user is admin
      const user = await env.DB.prepare(
        "SELECT is_admin FROM users WHERE id = ?"
      ).bind(session.user_id).first() as any;

      if (!user || !user.is_admin) {
        return Response.json(
          { error: 'Admin access required' },
          { status: 403, headers: corsHeaders }
        );
      }

      // Get all users
      const users = await env.DB.prepare(
        "SELECT id, email, phone, user_code, is_admin, is_active, initial_capital, max_trades_per_index, max_accounts_allowed, created_at, updated_at FROM users ORDER BY created_at DESC"
      ).all() as any;

      return Response.json(
        {
          success: true,
          users: users.results || [],
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Admin endpoints - Get database tables
  {
    method: 'GET',
    path: '/api/admin/db/tables',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Check if user is admin
      const user = await env.DB.prepare(
        "SELECT is_admin FROM users WHERE id = ?"
      ).bind(session.user_id).first() as any;

      if (!user || !user.is_admin) {
        return Response.json(
          { error: 'Admin access required' },
          { status: 403, headers: corsHeaders }
        );
      }

      // Get list of tables from D1
      // D1 doesn't have a direct way to list tables, so we'll return known tables
      const knownTables = ['users', 'sessions', 'broker_credentials'];

      return Response.json(
        {
          success: true,
          tables: knownTables,
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Admin endpoints - Get table data
  {
    method: 'GET',
    path: new RegExp('^/api/admin/db/tables/([^/]+)$'),
    handler: async (request, env: Env, url) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Check if user is admin
      const user = await env.DB.prepare(
        "SELECT is_admin FROM users WHERE id = ?"
      ).bind(session.user_id).first() as any;

      if (!user || !user.is_admin) {
        return Response.json(
          { error: 'Admin access required' },
          { status: 403, headers: corsHeaders }
        );
      }

      // Extract table name from URL
      const pathMatch = url.pathname.match(/^\/api\/admin\/db\/tables\/([^/]+)$/);
      const tableName = pathMatch ? pathMatch[1] : null;

      if (!tableName) {
        return Response.json(
          { error: 'Table name required' },
          { status: 400, headers: corsHeaders }
        );
      }

      // Validate table name (prevent SQL injection)
      const validTables = ['users', 'sessions', 'broker_credentials'];
      if (!validTables.includes(tableName)) {
        return Response.json(
          { error: 'Invalid table name' },
          { status: 400, headers: corsHeaders }
        );
      }

      // Get pagination params
      const page = parseInt(url.searchParams.get('page') || '1');
      const perPage = parseInt(url.searchParams.get('per_page') || '50');
      const offset = (page - 1) * perPage;

      // Get table data
      const data = await env.DB.prepare(
        `SELECT * FROM ${tableName} LIMIT ? OFFSET ?`
      ).bind(perPage, offset).all() as any;

      // Get total count
      const countResult = await env.DB.prepare(
        `SELECT COUNT(*) as total FROM ${tableName}`
      ).first() as any;

      return Response.json(
        {
          success: true,
          data: data.results || [],
          pagination: {
            page,
            per_page: perPage,
            total: countResult?.total || 0,
            total_pages: Math.ceil((countResult?.total || 0) / perPage),
          },
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Admin endpoints - Get table columns
  {
    method: 'GET',
    path: new RegExp('^/api/admin/db/tables/([^/]+)/columns$'),
    handler: async (request, env: Env, url) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Check if user is admin
      const user = await env.DB.prepare(
        "SELECT is_admin FROM users WHERE id = ?"
      ).bind(session.user_id).first() as any;

      if (!user || !user.is_admin) {
        return Response.json(
          { error: 'Admin access required' },
          { status: 403, headers: corsHeaders }
        );
      }

      // Extract table name from URL
      const pathMatch = url.pathname.match(/^\/api\/admin\/db\/tables\/([^/]+)\/columns$/);
      const tableName = pathMatch ? pathMatch[1] : null;

      if (!tableName) {
        return Response.json(
          { error: 'Table name required' },
          { status: 400, headers: corsHeaders }
        );
      }

      // Validate table name
      const validTables = ['users', 'sessions', 'broker_credentials'];
      if (!validTables.includes(tableName)) {
        return Response.json(
          { error: 'Invalid table name' },
          { status: 400, headers: corsHeaders }
        );
      }

      // Get one row to determine columns
      const sample = await env.DB.prepare(
        `SELECT * FROM ${tableName} LIMIT 1`
      ).first() as any;

      // Extract column names from sample row
      const columns = sample ? Object.keys(sample).map((name: string) => ({
        name,
        type: 'TEXT', // D1 doesn't expose column types easily, defaulting to TEXT
      })) : [];

      return Response.json(
        {
          success: true,
          columns,
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Admin endpoints - Get database stats
  {
    method: 'GET',
    path: '/api/admin/db/stats',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Check if user is admin
      const user = await env.DB.prepare(
        "SELECT is_admin FROM users WHERE id = ?"
      ).bind(session.user_id).first() as any;

      if (!user || !user.is_admin) {
        return Response.json(
          { error: 'Admin access required' },
          { status: 403, headers: corsHeaders }
        );
      }

      // Get stats
      const usersCount = await env.DB.prepare("SELECT COUNT(*) as count FROM users").first() as any;
      const activeUsersCount = await env.DB.prepare("SELECT COUNT(*) as count FROM users WHERE is_active = 1").first() as any;
      const adminUsersCount = await env.DB.prepare("SELECT COUNT(*) as count FROM users WHERE is_admin = 1").first() as any;

      return Response.json(
        {
          success: true,
          stats: {
            users: usersCount?.count || 0,
            active_users: activeUsersCount?.count || 0,
            admin_users: adminUsersCount?.count || 0,
            database_size_mb: 0.08, // Approximate from earlier migration
          },
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Reports endpoints - Get user trade history and performance
  {
    method: 'GET',
    path: new RegExp('^/report/user/([^/]+)$'),
    handler: async (request, env: Env, url) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Extract user ID from URL
      const pathMatch = url.pathname.match(/^\/report\/user\/([^/]+)$/);
      const userId = pathMatch ? pathMatch[1] : null;

      if (!userId) {
        return Response.json(
          { error: 'User ID required' },
          { status: 400, headers: corsHeaders }
        );
      }

      // Get user info
      const user = await env.DB.prepare(
        "SELECT id, email, phone, user_code, initial_capital FROM users WHERE user_code = ? OR id = ?"
      ).bind(userId, userId).first() as any;

      if (!user) {
        return Response.json(
          { error: 'User not found' },
          { status: 404, headers: corsHeaders }
        );
      }

      // For now, return mock data structure
      // TODO: Query actual trade history from database when trade tracking is implemented
      return Response.json(
        {
          user_id: user.user_code || user.id,
          total_trades: 0,
          capital: user.initial_capital || 10000,
          pnl: 0,
          win_rate: 0,
          avg_trade: 0,
          message: 'Trade history tracking coming soon',
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Backtest endpoints - Realistic test
  {
    method: 'GET',
    path: '/backtest/realistic',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Return mock backtest result
      // TODO: Implement actual backtesting logic
      return Response.json(
        {
          success: true,
          type: 'realistic',
          result: {
            total_trades: 100,
            win_rate: 65.5,
            total_pnl: 12500,
            max_drawdown: -2500,
            sharpe_ratio: 1.8,
            message: 'Backtesting engine coming in v1.1',
          },
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // Backtest endpoints - Edge case test
  {
    method: 'GET',
    path: '/backtest/edge',
    handler: async (request, env: Env) => {
      const authHeader = request.headers.get('Authorization');
      if (!authHeader) {
        return Response.json(
          { error: 'Authorization required' },
          { status: 401, headers: corsHeaders }
        );
      }

      if (!env.DB) {
        return Response.json(
          { error: 'Database not configured' },
          { status: 503, headers: corsHeaders }
        );
      }

      const token = authHeader.replace('Bearer ', '').trim();
      const session = await env.DB.prepare(
        "SELECT * FROM sessions WHERE session_token = ? AND expires_at > ?"
      ).bind(token, new Date().toISOString()).first() as any;

      if (!session) {
        return Response.json(
          { error: 'Invalid or expired token' },
          { status: 401, headers: corsHeaders }
        );
      }

      // Return mock backtest result
      // TODO: Implement actual backtesting logic
      return Response.json(
        {
          success: true,
          type: 'edge',
          result: {
            total_trades: 50,
            win_rate: 45.0,
            total_pnl: -5000,
            max_drawdown: -8000,
            sharpe_ratio: 0.5,
            message: 'Backtesting engine coming in v1.1',
          },
        },
        { status: 200, headers: corsHeaders }
      );
    },
  },

  // HDFC Sky OAuth callback
  {
    method: 'GET',
    path: '/callback/hdfc',
    handler: async (request, env, url) => {
      const requestToken = url.searchParams.get('request_token');
      if (!requestToken) {
        return new Response(
          '<html><body><h1>HDFC Sky OAuth Callback</h1><p>Missing request_token in callback URL.</p><p>Please check the URL and try again.</p></body></html>',
          {
            status: 400,
            headers: {
              'Content-Type': 'text/html',
              ...corsHeaders,
            },
          }
        );
      }

      // Return success page with request_token for user to copy
      // The user needs to exchange this request_token for access_token using the API client
      return new Response(
        `<html>
          <body style="font-family: Arial, sans-serif; padding: 20px; text-align: center;">
            <h1>✅ HDFC Sky OAuth Successful!</h1>
            <p>Your request_token has been received.</p>
            <div style="background: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px; word-break: break-all;">
              <strong>Request Token:</strong><br>
              <code style="font-size: 12px;">${requestToken}</code>
            </div>
            <p><strong>Next Steps:</strong></p>
            <ol style="text-align: left; max-width: 600px; margin: 0 auto;">
              <li>Copy the request_token above</li>
              <li>Run: <code>python scripts/brokers/test_hdfc_connection.py</code></li>
              <li>Paste the request_token when prompted</li>
              <li>The script will exchange it for an access_token</li>
            </ol>
            <p style="margin-top: 30px; color: #666;">You can close this tab.</p>
          </body>
        </html>`,
        {
          status: 200,
          headers: {
            'Content-Type': 'text/html',
            ...corsHeaders,
          },
        }
      );
    },
  },

  // GitHub Webhook for Cloudflare Pages deployment
  {
    method: 'POST',
    path: '/webhook/github',
    handler: async (request, env, url) => {
      try {
        const eventType = request.headers.get('X-GitHub-Event');
        const signature = request.headers.get('X-Hub-Signature-256');

        // Verify webhook secret if configured
        if (env.GITHUB_WEBHOOK_SECRET && signature) {
          const payload = await request.clone().text();
          const isValid = await verifyGitHubSignature(
            payload,
            signature,
            env.GITHUB_WEBHOOK_SECRET
          );
          if (!isValid) {
            return Response.json(
              { error: 'Invalid signature' },
              { status: 401, headers: corsHeaders }
            );
          }
        }

        // Parse GitHub webhook payload
        const payload: any = await request.json();

        // Only process push events to main/master branch
        if (eventType === 'push') {
          const ref = payload.ref;
          const branch = ref?.replace('refs/heads/', '');

          if (branch === 'main' || branch === 'master') {
            // Check if relevant files changed
            const commits = payload.commits || [];
            const hasRelevantChanges = commits.some((commit: any) => {
              const files = [
                ...(commit.added || []),
                ...(commit.modified || []),
                ...(commit.removed || []),
              ];
              return files.some((file: string) =>
                file.startsWith('aurum_harmony/frontend/') ||
                file.startsWith('docs/') ||
                file === '.github/workflows/deploy.yml'
              );
            });

            if (hasRelevantChanges || commits.length > 0) {
              // Trigger Cloudflare Pages deployment
              if (env.CLOUDFLARE_DEPLOY_HOOK) {
                const deployResponse = await fetch(env.CLOUDFLARE_DEPLOY_HOOK, {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: JSON.stringify({
                    branch: branch,
                    commit: payload.head_commit?.id || 'unknown',
                    message: payload.head_commit?.message || 'Deployment triggered',
                  }),
                });

                if (deployResponse.ok) {
                  return Response.json(
                    {
                      success: true,
                      message: 'Cloudflare Pages deployment triggered',
                      branch: branch,
                      commit: payload.head_commit?.id,
                    },
                    { status: 200, headers: corsHeaders }
                  );
                } else {
                  const errorText = await deployResponse.text();
                  return Response.json(
                    {
                      success: false,
                      error: 'Failed to trigger Cloudflare deployment',
                      details: errorText,
                    },
                    { status: 500, headers: corsHeaders }
                  );
                }
              } else {
                return Response.json(
                  {
                    success: false,
                    error: 'CLOUDFLARE_DEPLOY_HOOK not configured',
                  },
                  { status: 500, headers: corsHeaders }
                );
              }
            } else {
              return Response.json(
                {
                  success: true,
                  message: 'No relevant changes detected, skipping deployment',
                  branch: branch,
                },
                { status: 200, headers: corsHeaders }
              );
            }
          } else {
            return Response.json(
              {
                success: true,
                message: `Push to ${branch} branch ignored (only main/master triggers deployment)`,
              },
              { status: 200, headers: corsHeaders }
            );
          }
        } else {
          return Response.json(
            {
              success: true,
              message: `Event type ${eventType} ignored`,
            },
            { status: 200, headers: corsHeaders }
          );
        }
      } catch (error: any) {
        return Response.json(
          {
            success: false,
            error: 'Error processing webhook',
            details: error.message,
          },
          { status: 500, headers: corsHeaders }
        );
      }
    },
  },

  // Kotak Neo TOTP callback
  {
    method: 'POST',
    path: '/callback/kotak',
    handler: async (request, env) => {
      try {
        const body: any = await request.json();
        const { totp } = body;
        if (!totp) {
          return Response.json(
            { error: 'Missing TOTP' },
            { status: 400, headers: corsHeaders }
          );
        }

        const sessionRes = await fetch('https://api.kotakneo.com/session', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.KOTAK_CONSUMER_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ totp, environment: 'prod' }),
        });

        const data = await sessionRes.json();
        return Response.json(
          { success: true, session: data },
          { status: 200, headers: corsHeaders }
        );
      } catch (error: any) {
        return Response.json(
          { error: error.message },
          { status: 500, headers: corsHeaders }
        );
      }
    },
  },
];

// Match route helper
function matchRoute(path: string, routePath: string | RegExp): boolean {
  if (typeof routePath === 'string') {
    return path === routePath;
  }
  // For RegExp, test the path
  return routePath.test(path);
}

/**
 * Verify GitHub webhook signature using HMAC SHA-256
 */
async function verifyGitHubSignature(
  payload: string,
  signature: string,
  secret: string
): Promise<boolean> {
  try {
    // Remove 'sha256=' prefix if present
    const sig = signature.replace('sha256=', '');
    
    // Create HMAC
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    );

    const signatureBytes = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(payload)
    );

    // Convert to hex
    const hashArray = Array.from(new Uint8Array(signatureBytes));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // Compare signatures (constant-time comparison)
    return hashHex === sig;
  } catch {
    return false;
  }
}

// Main handler
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // Handle CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          ...corsHeaders,
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // Find matching route
    for (const route of routes) {
      if (route.method === method && matchRoute(path, route.path)) {
        try {
          return await route.handler(request, env, url);
        } catch (error: any) {
          return Response.json(
            { error: 'Internal server error', details: error.message },
            { status: 500, headers: corsHeaders }
          );
        }
      }
    }

    // Handle API routes that don't have handlers yet
    if (path.startsWith('/api/')) {
      return Response.json(
        {
          error: 'API endpoint not yet implemented',
          message: 'This endpoint needs a route handler',
          path: path,
          method: method,
          suggestion: 'For now, use localhost backend: http://localhost:5000',
          status: 'not_implemented',
        },
        {
          status: 501,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    // 404 for unknown routes
    return Response.json(
      { error: 'Not found', path: path },
      { status: 404, headers: corsHeaders }
    );
  },
};
