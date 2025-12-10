/**
 * Authentication utilities for Cloudflare Worker
 * Handles password hashing, JWT tokens, and session management
 */

// Simple password hashing using Web Crypto API (bcrypt alternative for Workers)
export async function hashPassword(password: string): Promise<string> {
  // Use Web Crypto API to create a hash
  // Note: This is a simplified version. For production, consider using a proper bcrypt library
  // or Cloudflare's built-in crypto
  
  const encoder = new TextEncoder();
  const data = encoder.encode(password);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  
  // Add salt (in production, use a proper salt)
  const salt = await generateSalt();
  return `${salt}:${hashHex}`;
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  // Check if this is a bcrypt hash (starts with $2a$, $2b$, or $2y$)
  // Flask backend uses bcrypt, but Cloudflare Workers don't support bcrypt natively
  if (hash.startsWith('$2a$') || hash.startsWith('$2b$') || hash.startsWith('$2y$')) {
    // This is a bcrypt hash from Flask backend
    // Workers cannot verify bcrypt - need to use Flask backend for login
    console.warn('bcrypt hash detected - Worker cannot verify bcrypt hashes. Use Flask backend for login.');
    return false;
  }
  
  // Handle SHA-256 hashes (format: salt:hash)
  const [salt, storedHash] = hash.split(':');
  if (!salt || !storedHash) {
    return false;
  }
  
  const encoder = new TextEncoder();
  const data = encoder.encode(password + salt);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  
  return hashHex === storedHash;
}

async function generateSalt(): Promise<string> {
  const array = new Uint8Array(16);
  crypto.getRandomValues(array);
  return Array.from(array, b => b.toString(16).padStart(2, '0')).join('');
}

// JWT-like token generation (simplified)
export async function generateSessionToken(userId: number, secret: string): Promise<string> {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };
  
  const payload = {
    userId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60) // 7 days
  };
  
  // Simple base64 encoding (in production, use proper JWT library)
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  
  // Create signature
  const signature = await createSignature(`${headerB64}.${payloadB64}`, secret);
  
  return `${headerB64}.${payloadB64}.${signature}`;
}

export async function verifySessionToken(token: string, secret: string): Promise<{ userId: number; valid: boolean }> {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return { userId: 0, valid: false };
    }
    
    const [headerB64, payloadB64, signature] = parts;
    
    // Verify signature
    const isValid = await verifySignature(`${headerB64}.${payloadB64}`, signature, secret);
    if (!isValid) {
      return { userId: 0, valid: false };
    }
    
    // Decode payload
    const payload = JSON.parse(atob(payloadB64.replace(/-/g, '+').replace(/_/g, '/')));
    
    // Check expiration
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
      return { userId: 0, valid: false };
    }
    
    return { userId: payload.userId, valid: true };
  } catch {
    return { userId: 0, valid: false };
  }
}

async function createSignature(data: string, secret: string): Promise<string> {
  // Use Web Crypto API for HMAC-SHA256
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(data);
  
  const key = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  
  const signature = await crypto.subtle.sign('HMAC', key, messageData);
  const hashArray = Array.from(new Uint8Array(signature));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  
  return btoa(hashHex).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_').substring(0, 43);
}

async function verifySignature(data: string, signature: string, secret: string): Promise<boolean> {
  const expected = await createSignature(data, secret);
  return signature === expected;
}

export function generateUserCode(): string {
  // Generate unique user code like "user001", "user002", etc.
  // In production, you'd query the database to get the next number
  const random = Math.random().toString(36).substring(2, 8);
  return `user${random}`;
}

export function generateEmailVerificationToken(): string {
  // Generate a secure random token for email verification
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, b => b.toString(16).padStart(2, '0')).join('');
}
