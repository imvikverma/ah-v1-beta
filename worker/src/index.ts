/**
 * AurumHarmony API Worker
 * 
 * This is a minimal Worker that handles basic health checks.
 * Full API endpoints should be migrated from Flask to Worker handlers.
 * 
 * For now, this Worker provides:
 * - Health check endpoint
 * - Basic error handling
 * - CORS headers
 */

export default {
  async fetch(request: Request, env: any, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // Health check endpoint
    if (path === '/health' || path === '/') {
      return new Response(
        JSON.stringify({
          status: 'AurumHarmony API v1 – Running',
          worker: true,
          timestamp: new Date().toISOString(),
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // API endpoints - TODO: Migrate from Flask
    if (path.startsWith('/api/')) {
      // For now, return a helpful error message
      return new Response(
        JSON.stringify({
          error: 'API endpoint not yet migrated to Worker',
          message: 'This endpoint needs to be migrated from Flask to Worker handlers',
          path: path,
          suggestion: 'Use localhost:5000 for development until migration is complete',
        }),
        {
          status: 501, // Not Implemented
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      );
    }

    // 404 for unknown routes
    return new Response(
      JSON.stringify({
        error: 'Not Found',
        path: path,
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  },
};

