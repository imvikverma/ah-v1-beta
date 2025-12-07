# Admin Module - Monthly Birthday & Anniversary Reports

This module handles monthly email reports for birthdays and anniversaries, sent to the admin email address.

## Features

- **Monthly Reports**: Automatically sends birthday and anniversary reports on the 1st of each month
- **Manual Trigger**: Can be triggered manually via API or script
- **HTML & Plain Text**: Sends both HTML and plain text email versions
- **Admin API**: RESTful endpoints for viewing and sending reports

## Setup

### 1. Environment Variables

Set the following environment variables for email functionality:

```bash
# SMTP Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_SENDER=alerts@aurumharmony.in
SMTP_PASSWORD=your_app_password_here

# Admin Email (recipient)
ADMIN_REPORT_EMAIL=vikrm@saffronbolt.in
```

**For Gmail:**
- Use an App Password (not your regular password)
- Enable 2-Factor Authentication
- Generate App Password: https://myaccount.google.com/apppasswords

### 2. Database Migration

Run the migration to add new user fields:

```bash
python aurum_harmony/database/migrate.py
```

This will add:
- `date_of_birth` column
- `anniversary` column
- `initial_capital` column
- `max_trades_per_index` column
- `max_accounts_allowed` column

## Usage

### Manual Trigger (Python Script)

```bash
# Send report for current month
python aurum_harmony/admin/scheduler.py

# Send report for specific month/year
python aurum_harmony/admin/scheduler.py --month 12 --year 2024
```

### API Endpoints

#### Get Monthly Report Data
```http
GET /api/admin/notifications/birthdays-anniversaries?month=12&year=2024
Authorization: Bearer <admin_token>
```

#### Send Monthly Report Email
```http
POST /api/admin/notifications/send-monthly-report
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "month": 12,
  "year": 2024
}
```

### Scheduled Task (Cron/Windows Task Scheduler)

**Linux/Mac (Cron):**
```cron
# Run on the 1st of each month at 9:00 AM
0 9 1 * * cd /path/to/project && python aurum_harmony/admin/scheduler.py
```

**Windows Task Scheduler:**
1. Open Task Scheduler
2. Create Basic Task
3. Trigger: Monthly, Day 1, Time: 9:00 AM
4. Action: Start a program
5. Program: `python`
6. Arguments: `aurum_harmony/admin/scheduler.py`
7. Start in: `D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest`

## Email Format

The email includes:
- **Summary**: Total birthdays and anniversaries count
- **Birthdays Table**: User code, email, birthday day, fee waiver status
- **Anniversaries Table**: User code, email, anniversary day, fee discount status
- **HTML Formatting**: Professional styling with AurumHarmony branding

## Fee Policy

- **Birthdays**: Full fee waiver eligible (`fee_waiver_eligible: true`)
- **Anniversaries**: Fee discount eligible (`fee_discount_eligible: true`)
- Actual waiver/discount percentages to be determined

## Testing

Test the email service:

```python
from aurum_harmony.admin.email_service import admin_email_service
from aurum_harmony.admin.notifications import get_upcoming_birthdays_and_anniversaries

# Get current month summary
summary = get_upcoming_birthdays_and_anniversaries()

# Send test email
result = admin_email_service.send_monthly_birthday_anniversary_report(summary)
print(result)
```

## Troubleshooting

### Email Not Sending

1. **Check SMTP credentials**: Verify `SMTP_PASSWORD` is set correctly
2. **Check Gmail App Password**: Must use App Password, not regular password
3. **Check firewall**: Ensure port 587 is not blocked
4. **Check logs**: Review error messages in the email_result

### Common Errors

- `SMTP authentication failed`: Invalid password or App Password not set
- `SMTP_PASSWORD environment variable not set`: Missing environment variable
- `Connection timeout`: Firewall or network issue

## Files

- `routes.py`: Admin API endpoints
- `notifications.py`: Birthday/anniversary data fetching
- `email_service.py`: Email sending functionality
- `scheduler.py`: Scheduled task script

