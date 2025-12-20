from smtplib import SMTP

class NotificationSystem:
    def __init__(self):
        self.smtp_server = SMTP('smtp.gmail.com', 587)

    def send_alert(self, user_email, message):
        self.smtp_server.starttls()
        self.smtp_server.login("aurumharmony@gmail.com", "password")
        self.smtp_server.sendmail("aurumharmony@gmail.com", user_email, f"Subject: Alert\n\n{message}")
        self.smtp_server.quit()

# Example usage
notif = NotificationSystem()
notif.send_alert("user@example.com", "Switch to Put: RSI 72")