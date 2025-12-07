/**
 * api.ah.saffronbolt.in – AurumHarmony Broker API (HDFC Sky + Kotak Neo)
 * 
 * This Worker handles:
 * - Health checks
 * - HDFC Sky OAuth callbacks
 * - Kotak Neo TOTP callbacks
 * - API endpoints (returns 501 until migrated from Flask)
 */

export default {
  async fetch(request: Request, env: any): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // Handle CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // CORS headers for all responses
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    };

    // Health check
    if (path === '/health' || path === '/') {
      return new Response('AurumHarmony API Live', {
        status: 200,
        headers: {
          'Content-Type': 'text/plain',
          ...corsHeaders,
        },
      });
    }

    // === HDFC SKY OAuth callback ===
    if (path === '/callback/hdfc') {
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
        
        // Return success page
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
      } catch (error) {
        return new Response(`Error: ${error.message}`, {
          status: 500,
          headers: corsHeaders,
        });
      }
    }

    // === KOTAK NEO TOTP callback ===
    if (path === '/callback/kotak' && method === 'POST') {
      try {
        const { totp } = await request.json();
        if (!totp) {
          return Response.json(
            { error: 'Missing TOTP' },
            {
              status: 400,
              headers: corsHeaders,
            }
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
          {
            status: 200,
            headers: corsHeaders,
          }
        );
      } catch (error) {
        return Response.json(
          { error: error.message },
          {
            status: 500,
            headers: corsHeaders,
          }
        );
      }
    }

    // === API Endpoints (Flask routes - need migration) ===
    if (path.startsWith('/api/')) {
      // Return helpful error message for unmigrated endpoints
      return Response.json(
        {
          error: 'API endpoint not yet migrated to Worker',
          message: 'This endpoint needs to be migrated from Flask to Worker handlers',
          path: path,
          suggestion: 'For development, use localhost:5000 backend. Access app from http://localhost:58643',
          status: 'not_implemented',
        },
        {
          status: 501, // Not Implemented
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }

    // Placeholder endpoints – ready for future
    if (path === '/order' && method === 'POST') {
      return Response.json(
        { status: 'order endpoint ready' },
        {
          headers: corsHeaders,
        }
      );
    }

    // Default response
    return new Response('AurumHarmony API v1 – Running', {
      status: 200,
      headers: {
        'Content-Type': 'text/plain',
        ...corsHeaders,
      },
    });
  },
};
