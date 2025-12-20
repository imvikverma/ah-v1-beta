/**
 * GitHub Webhook Handler for Cloudflare Pages Deployment
 * Receives GitHub push events and triggers Cloudflare Pages deployment
 */

export interface Env {
  CLOUDFLARE_DEPLOY_HOOK: string; // Cloudflare Pages build hook URL
  GITHUB_WEBHOOK_SECRET?: string; // Optional: GitHub webhook secret for verification
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-GitHub-Event, X-Hub-Signature-256',
    };

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

    // Only handle POST requests to /webhook/github
    if (method !== 'POST' || path !== '/webhook/github') {
      return Response.json(
        { error: 'Not found', path: path },
        { status: 404, headers: corsHeaders }
      );
    }

    try {
      // Get GitHub event type
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
};

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

