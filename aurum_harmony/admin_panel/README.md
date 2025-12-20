# AurumHarmony Admin Panel

A comprehensive web-based admin interface for AurumHarmony trading platform management.

## Features

### User Management
- View all registered users with detailed information
- Edit user profiles, capital, and status
- Activate/deactivate user accounts
- Monitor user activity and login history
- Admin role management

### System Monitoring
- Real-time system status indicators
- Database health monitoring
- AI engine performance metrics
- Market data connection status
- Security monitoring

### Analytics & Reports
- Trading performance metrics
- User activity analytics
- System performance statistics
- Revenue analytics
- Export capabilities

### System Administration
- Database backup functionality
- Service restart capabilities
- System health checks
- Configuration management

## Deployment

### Cloudflare Pages Deployment

1. **Create a new site** in Cloudflare Pages
2. **Connect repository** or upload files directly
3. **Build settings**:
   - Build command: (leave empty - static site)
   - Build output directory: `/`
4. **Environment variables** (if needed):
   - `API_BASE_URL`: Backend API URL
5. **Custom domain**: `admin-v2.saffronbolt.in`

### Security Configuration

The admin panel includes:
- Secure authentication via JWT tokens
- Admin-only access controls
- HTTPS enforcement
- CORS protection
- Content Security Policy headers

## File Structure

```
admin_panel/
├── index.html          # Main admin interface
├── styles.css          # Responsive styling
├── script.js          # Frontend functionality
├── _headers           # Cloudflare security headers
└── README.md          # This file
```

## API Integration

The admin panel connects to the AurumHarmony backend via REST APIs:

- `GET /api/admin/users` - List all users
- `POST /api/admin/users/{id}/status` - Toggle user status
- `PUT /api/admin/users/{id}` - Update user details
- `GET /api/admin/stats` - System statistics
- `GET /api/admin/reports` - Administrative reports

## Authentication

Admin users must authenticate through the main application with admin privileges. The admin panel uses JWT tokens for secure API communication.

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Development

To run locally for development:

1. Serve the files using any static server
2. Update `API_BASE_URL` in `script.js` to point to your backend
3. Open in browser

Example using Python:
```bash
cd admin_panel
python -m http.server 8080
```

## Security Notes

- All API calls require valid JWT tokens
- Admin-only endpoints are protected server-side
- Client-side validation is for UX only
- Sensitive operations require confirmation dialogs
- Session management with automatic logout on token expiry

## Support

For technical support or feature requests, contact the development team at saffronbolt.in.
