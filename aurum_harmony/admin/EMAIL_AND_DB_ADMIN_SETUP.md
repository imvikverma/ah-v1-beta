# Email & Database Admin Setup Guide

## 1. Cloudflare Email Routing / DMARC Support

### Overview
The email service now supports Cloudflare Email Routing, which uses your domain's SMTP server instead of Gmail.

### Configuration

**Option A: Cloudflare Email Routing (Recommended)**
```bash
USE_CLOUDFLARE_EMAIL=true
SMTP_SERVER=smtp.saffronbolt.in  # Your domain's SMTP
SMTP_PORT=587
SMTP_SENDER=alerts@saffronbolt.in  # Use your domain email
SMTP_PASSWORD=your_smtp_password
ADMIN_REPORT_EMAIL=vikrm@saffronbolt.in
```

**Option B: Gmail (Standard)**
```bash
USE_CLOUDFLARE_EMAIL=false
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_SENDER=alerts@aurumharmony.in
SMTP_PASSWORD=your_gmail_app_password
ADMIN_REPORT_EMAIL=vikrm@saffronbolt.in
```

### Cloudflare Email Routing Setup
1. Go to Cloudflare Dashboard → Email → Email Routing
2. Enable Email Routing for `saffronbolt.in`
3. Add destination address: `vikrm@saffronbolt.in`
4. Configure SMTP settings (usually provided by Cloudflare)
5. Set `SMTP_PASSWORD` to your Cloudflare Email Routing password

### DMARC Management
DMARC is already configured via Cloudflare:
- TXT record: `_dmarc.saffronbolt.in` → `v=DMARC1; p=none; rua=mailto:...@dmarc-reports.cloudflare.net`
- Reports go to Cloudflare's DMARC reporting system
- No additional configuration needed

## 2. Database Admin Widget

### Features
- **View Database Tables**: Browse all database tables (users, broker_credentials, sessions)
- **View Table Data**: See all records in a table with pagination
- **View Table Schema**: See column information (name, type, nullable, etc.)
- **Database Statistics**: View counts and database size
- **Safe Query Execution**: Execute SELECT queries only (for security)

### Access
1. Open the Flutter app
2. Navigate to **Admin** tab
3. Click on **Database** tab
4. Select a table from the sidebar to view data

### API Endpoints

#### Get All Tables
```http
GET /api/admin/db/tables
Authorization: Bearer <admin_token>
```

#### Get Table Data
```http
GET /api/admin/db/tables/<table_name>?page=1&per_page=50
Authorization: Bearer <admin_token>
```

#### Get Table Columns
```http
GET /api/admin/db/tables/<table_name>/columns
Authorization: Bearer <admin_token>
```

#### Execute Query (SELECT only)
```http
POST /api/admin/db/query
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "query": "SELECT * FROM users WHERE is_active = 1"
}
```

#### Get Database Stats
```http
GET /api/admin/db/stats
Authorization: Bearer <admin_token>
```

### Security
- **Admin Only**: All endpoints require admin authentication
- **Read-Only**: Only SELECT queries are allowed (no INSERT/UPDATE/DELETE)
- **Table Whitelist**: Only specific tables are accessible (users, broker_credentials, sessions)
- **Pagination**: Results are paginated (max 100 records per page)

### Usage Tips
1. **Refresh Tables**: Click the refresh icon to reload table list
2. **View Data**: Click on any table name to view its data
3. **Scroll**: Tables with many columns/rows are scrollable
4. **Stats**: Database statistics show at the top of the Database tab

## Troubleshooting

### Email Not Sending
1. Check `SMTP_PASSWORD` is set correctly
2. Verify SMTP server and port settings
3. For Cloudflare: Check Email Routing is enabled
4. Check firewall allows SMTP port 587

### Database Admin Not Loading
1. Verify you're logged in as admin
2. Check backend is running and accessible
3. Verify admin API endpoints are registered
4. Check browser console for errors

### Permission Denied
- Ensure your user account has `is_admin = true` in the database
- Check JWT token includes admin status
- Verify admin endpoints are properly protected

