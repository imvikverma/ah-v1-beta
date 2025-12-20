"""
Scheduled tasks for admin operations.
Handles monthly birthday and anniversary report emails.
"""

import os
import sys
from datetime import datetime
from pathlib import Path

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from flask import Flask
from aurum_harmony.database.db import init_db
from aurum_harmony.admin.notifications import get_upcoming_birthdays_and_anniversaries
from aurum_harmony.admin.email_service import admin_email_service


def send_monthly_report_task(month: int = None, year: int = None):
    """
    Scheduled task to send monthly birthday and anniversary report.
    Should be called on the 1st of each month.
    
    Args:
        month: Month number (1-12). If None, uses current month.
        year: Year number. If None, uses current year.
    """
    print("=" * 60)
    print("AurumHarmony Monthly Report Task")
    print("=" * 60)
    print()
    
    if month is None:
        month = datetime.now().month
    if year is None:
        year = datetime.now().year
    
    try:
        # Create Flask app for database context
        app = Flask(__name__)
        init_db(app)
        
        with app.app_context():
            print(f"Fetching birthdays and anniversaries for {datetime(year, month, 1).strftime('%B %Y')}...")
            
            # Get summary
            summary = get_upcoming_birthdays_and_anniversaries(month=month, year=year)
            
            print(f"Found {summary['total_birthdays']} birthdays and {summary['total_anniversaries']} anniversaries")
            print()
            
            # Send email
            print(f"Sending report to {admin_email_service.admin_email}...")
            email_result = admin_email_service.send_monthly_birthday_anniversary_report(
                summary=summary,
                month=month,
                year=year
            )
            
            if email_result.get('success'):
                print("✅ Monthly report sent successfully!")
                print(f"   Recipient: {email_result.get('recipient')}")
                print(f"   Month: {email_result.get('month')}/{email_result.get('year')}")
            else:
                print("❌ Failed to send monthly report")
                print(f"   Error: {email_result.get('error', 'Unknown error')}")
                print(f"   Message: {email_result.get('message', 'No details')}")
                return False
        
        print()
        print("=" * 60)
        print("✅ Task completed")
        print("=" * 60)
        return True
        
    except Exception as e:
        print(f"❌ Task failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == '__main__':
    """Run the monthly report task manually."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Send monthly birthday and anniversary report')
    parser.add_argument('--month', type=int, help='Month number (1-12)')
    parser.add_argument('--year', type=int, help='Year number')
    
    args = parser.parse_args()
    
    success = send_monthly_report_task(month=args.month, year=args.year)
    sys.exit(0 if success else 1)

