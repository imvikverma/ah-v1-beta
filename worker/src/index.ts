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

import { hashPassword, verifyPassword, generateSessionToken, verifySessionToken, generateUserCode } from './auth';

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
        const body = await request.json();
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

        // Check if database is available
        if (!env.DB) {
          return Response.json(
            { error: 'Database not configured', message: 'D1 database binding not found' },
            { status: 503, headers: corsHeaders }
          );
        }

        // Query user from database
        let user;
        if (email) {
          const result = await env.DB.prepare(
            "SELECT * FROM users WHERE email = ? AND is_active = 1"
          ).bind(email).first();
          user = result as any;
        } else {
          const result = await env.DB.prepare(
            "SELECT * FROM users WHERE phone = ? AND is_active = 1"
          ).bind(phone).first();
          user = result as any;
        }

        if (!user) {
          return Response.json(
            { error: 'Invalid credentials' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Verify password
        const isValid = await verifyPassword(password, user.password_hash);
        if (!isValid) {
          return Response.json(
            { error: 'Invalid credentials' },
            { status: 401, headers: corsHeaders }
          );
        }

        // Generate session token
        const jwtSecret = env.JWT_SECRET || 'default-secret-change-in-production';
        const sessionToken = await generateSessionToken(user.id, jwtSecret);
        
        // Store session in database
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // 7 days
        const now = new Date().toISOString();
        
        await env.DB.prepare(
          "INSERT INTO sessions (user_id, session_token, expires_at, created_at, last_accessed) VALUES (?, ?, ?, ?, ?)"
        ).bind(user.id, sessionToken, expiresAt, now, now).run();

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
          { error: 'Internal server error', details: error.message },
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
        const body = await request.json();
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

        // Check if database is available
        if (!env.DB) {
          return Response.json(
            { error: 'Database not configured', message: 'D1 database binding not found' },
            { status: 503, headers: corsHeaders }
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

        // Insert user
        const now = new Date().toISOString();
        const result = await env.DB.prepare(
          `INSERT INTO users (email, phone, password_hash, user_code, is_admin, is_active, initial_capital, max_accounts_allowed, created_at, updated_at)
           VALUES (?, ?, ?, ?, 0, 1, 10000.0, 1, ?, ?)`
        ).bind(
          email,
          phone || null,
          passwordHash,
          finalUserCode,
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
              user_code: finalUserCode,
            },
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

  // HDFC Sky OAuth callback
  {
    method: 'GET',
    path: '/callback/hdfc',
    handler: async (request, env, url) => {
      const code = url.searchParams.get('code');
      if (!code) {
        return new Response('Missing code', {
          status: 400,
          headers: corsHeaders,
        });
      }

      try {
        const tokenRes = await fetch('https://api.hdfcsec.com/oauth/token', {
          method: 'POST',
          headers: {
            'Authorization': `Basic ${btoa(`${env.HDFC_CLIENT_ID}:${env.HDFC_CLIENT_SECRET}`)}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: `grant_type=authorization_code&code=${code}&redirect_uri=https://api.ah.saffronbolt.in/callback/hdfc`,
        });

        const data = await tokenRes.json();
        
        return new Response(
          '<html><body><h1>HDFC Sky login successful</h1><p>You can close this tab.</p></body></html>',
          {
            status: 200,
            headers: {
              'Content-Type': 'text/html',
              ...corsHeaders,
            },
          }
        );
      } catch (error: any) {
        return new Response(`Error: ${error.message}`, {
          status: 500,
          headers: corsHeaders,
        });
      }
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
        const payload = await request.json();

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
        const { totp } = await request.json();
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
