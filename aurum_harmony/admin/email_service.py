"""
Email service for sending admin reports.
Handles monthly birthday and anniversary reports.
"""

import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import Dict, List, Any


class AdminEmailService:
    """Service for sending admin emails."""
    
    def __init__(self):
        # Support for Cloudflare Email Routing (via SMTP) or direct SMTP
        # Cloudflare Email Routing uses SMTP with your domain
        use_cloudflare = os.getenv('USE_CLOUDFLARE_EMAIL', 'false').lower() == 'true'
        
        if use_cloudflare:
            # Cloudflare Email Routing SMTP settings
            self.smtp_server = os.getenv('SMTP_SERVER', 'smtp.saffronbolt.in')  # Your domain's SMTP
            self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
            self.sender_email = os.getenv('SMTP_SENDER', 'alerts@saffronbolt.in')  # Use your domain
        else:
            # Standard SMTP (Gmail, etc.)
            self.smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
            self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
            self.sender_email = os.getenv('SMTP_SENDER', 'alerts@aurumharmony.in')
        
        self.sender_password = os.getenv('SMTP_PASSWORD', '')  # Must be set via env var
        self.admin_email = os.getenv('ADMIN_REPORT_EMAIL', 'vikrm@saffronbolt.in')
    
    def send_monthly_birthday_anniversary_report(
        self,
        summary: Dict[str, Any],
        month: int = None,
        year: int = None
    ) -> Dict[str, Any]:
        """
        Send monthly birthday and anniversary report to admin.
        
        Args:
            summary: Dictionary from get_upcoming_birthdays_and_anniversaries()
            month: Month number (1-12)
            year: Year number
        
        Returns:
            Dictionary with send status
        """
        if month is None:
            month = datetime.now().month
        if year is None:
            year = datetime.now().year
        
        month_name = datetime(year, month, 1).strftime('%B %Y')
        
        # Create email content
        subject = f"AurumHarmony Monthly Report - Birthdays & Anniversaries - {month_name}"
        
        # Build HTML email body
        html_body = self._build_report_html(summary, month_name)
        
        # Build plain text fallback
        text_body = self._build_report_text(summary, month_name)
        
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = self.sender_email
            msg['To'] = self.admin_email
            
            # Attach both plain text and HTML versions
            part1 = MIMEText(text_body, 'plain')
            part2 = MIMEText(html_body, 'html')
            
            msg.attach(part1)
            msg.attach(part2)
            
            # Send email
            if not self.sender_password:
                return {
                    'success': False,
                    'error': 'SMTP_PASSWORD environment variable not set',
                    'message': 'Email not sent - SMTP credentials missing'
                }
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=30) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.send_message(msg)
            
            return {
                'success': True,
                'message': f'Monthly report sent successfully to {self.admin_email}',
                'recipient': self.admin_email,
                'month': month,
                'year': year,
                'timestamp': datetime.now().isoformat()
            }
            
        except smtplib.SMTPAuthenticationError as e:
            return {
                'success': False,
                'error': 'SMTP authentication failed',
                'message': str(e)
            }
        except smtplib.SMTPException as e:
            return {
                'success': False,
                'error': 'SMTP error',
                'message': str(e)
            }
        except Exception as e:
            return {
                'success': False,
                'error': 'Unexpected error',
                'message': str(e)
            }
    
    def _build_report_html(self, summary: Dict[str, Any], month_name: str) -> str:
        """Build HTML email body."""
        birthdays = summary.get('birthdays', [])
        anniversaries = summary.get('anniversaries', [])
        total_birthdays = summary.get('total_birthdays', 0)
        total_anniversaries = summary.get('total_anniversaries', 0)
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 800px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #f9a826 0%, #f57c00 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }}
                .content {{ background: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }}
                .section {{ margin-bottom: 30px; }}
                .section-title {{ font-size: 20px; font-weight: bold; color: #f9a826; margin-bottom: 15px; border-bottom: 2px solid #f9a826; padding-bottom: 5px; }}
                .summary {{ background: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
                .summary-item {{ display: inline-block; margin-right: 20px; }}
                .summary-number {{ font-size: 24px; font-weight: bold; color: #f9a826; }}
                .summary-label {{ font-size: 12px; color: #666; text-transform: uppercase; }}
                table {{ width: 100%; border-collapse: collapse; background: white; margin-top: 10px; }}
                th {{ background: #f9a826; color: white; padding: 12px; text-align: left; }}
                td {{ padding: 10px; border-bottom: 1px solid #ddd; }}
                tr:hover {{ background: #f5f5f5; }}
                .badge {{ display: inline-block; padding: 4px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; }}
                .badge-waiver {{ background: #4caf50; color: white; }}
                .badge-discount {{ background: #2196f3; color: white; }}
                .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Monthly Birthday & Anniversary Report</h1>
                    <p>{month_name}</p>
                </div>
                <div class="content">
                    <div class="summary">
                        <div class="summary-item">
                            <div class="summary-number">{total_birthdays}</div>
                            <div class="summary-label">Birthdays</div>
                        </div>
                        <div class="summary-item">
                            <div class="summary-number">{total_anniversaries}</div>
                            <div class="summary-label">Anniversaries</div>
                        </div>
                    </div>
        """
        
        # Birthdays section
        if birthdays:
            html += """
                    <div class="section">
                        <div class="section-title">🎂 Birthdays (Fee Waiver Eligible)</div>
                        <table>
                            <thead>
                                <tr>
                                    <th>User Code</th>
                                    <th>Email</th>
                                    <th>Birthday</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
            """
            for bday in birthdays:
                html += f"""
                                <tr>
                                    <td><strong>{bday.get('user_code', 'N/A')}</strong></td>
                                    <td>{bday.get('email', 'N/A')}</td>
                                    <td>{bday.get('birthday_day', 'N/A')} {month_name.split()[0]}</td>
                                    <td><span class="badge badge-waiver">Fee Waiver</span></td>
                                </tr>
                """
            html += """
                            </tbody>
                        </table>
                    </div>
            """
        else:
            html += """
                    <div class="section">
                        <div class="section-title">🎂 Birthdays</div>
                        <p>No birthdays this month.</p>
                    </div>
            """
        
        # Anniversaries section
        if anniversaries:
            html += """
                    <div class="section">
                        <div class="section-title">💍 Anniversaries (Fee Discount Eligible)</div>
                        <table>
                            <thead>
                                <tr>
                                    <th>User Code</th>
                                    <th>Email</th>
                                    <th>Anniversary</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
            """
            for anniv in anniversaries:
                html += f"""
                                <tr>
                                    <td><strong>{anniv.get('user_code', 'N/A')}</strong></td>
                                    <td>{anniv.get('email', 'N/A')}</td>
                                    <td>{anniv.get('anniversary_day', 'N/A')} {month_name.split()[0]}</td>
                                    <td><span class="badge badge-discount">Fee Discount</span></td>
                                </tr>
                """
            html += """
                            </tbody>
                        </table>
                    </div>
            """
        else:
            html += """
                    <div class="section">
                        <div class="section-title">💍 Anniversaries</div>
                        <p>No anniversaries this month.</p>
                    </div>
            """
        
        html += f"""
                    <div class="footer">
                        <p>This is an automated report from AurumHarmony Admin System.</p>
                        <p>Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    
    def _build_report_text(self, summary: Dict[str, Any], month_name: str) -> str:
        """Build plain text email body."""
        birthdays = summary.get('birthdays', [])
        anniversaries = summary.get('anniversaries', [])
        total_birthdays = summary.get('total_birthdays', 0)
        total_anniversaries = summary.get('total_anniversaries', 0)
        
        text = f"""
AurumHarmony Monthly Report - Birthdays & Anniversaries
{month_name}
{'=' * 60}

SUMMARY
{total_birthdays} Birthdays | {total_anniversaries} Anniversaries

"""
        
        if birthdays:
            text += "BIRTHDAYS (Fee Waiver Eligible)\n"
            text += "-" * 60 + "\n"
            for bday in birthdays:
                text += f"• {bday.get('user_code', 'N/A')} - {bday.get('email', 'N/A')} - Day {bday.get('birthday_day', 'N/A')}\n"
            text += "\n"
        else:
            text += "BIRTHDAYS\nNo birthdays this month.\n\n"
        
        if anniversaries:
            text += "ANNIVERSARIES (Fee Discount Eligible)\n"
            text += "-" * 60 + "\n"
            for anniv in anniversaries:
                text += f"• {anniv.get('user_code', 'N/A')} - {anniv.get('email', 'N/A')} - Day {anniv.get('anniversary_day', 'N/A')}\n"
            text += "\n"
        else:
            text += "ANNIVERSARIES\nNo anniversaries this month.\n\n"
        
        text += f"""
{'=' * 60}
This is an automated report from AurumHarmony Admin System.
Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        """
        
        return text


# Global instance
admin_email_service = AdminEmailService()

