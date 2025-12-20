# engines/notifications/Notifications.py
import smtplib
from email.mime.text import MIMEText
import time


class NotificationEngine:
    def __init__(self, hyperledger_client=None):
        self.hyperledger_client = hyperledger_client
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender = "alerts@aurumharmony.in"
        self.max_per_day = 5

    def send(self, user_id: str, email: str, message: str, profit: float = 0) -> dict:
        """
        Tiered alerts based on profit thresholds (per user)
        Basic: >₹5,000 | Pro: >₹8,000 | Elite: >₹10,000
        """
        thresholds = {"Basic": 5000, "Pro": 8000, "Elite": 10000}
        tier = "Basic"
        for t, val in thresholds.items():
            if profit > val:
                tier = t

        if profit <= thresholds["Basic"]:
            return {"status": "skipped", "reason": "below threshold"}

        msg = MIMEText(
            f"AurumHarmony Alert ({tier})\n\n{message}\nProfit: ₹{profit:,.0f}"
        )
        msg["Subject"] = f"AurumHarmony Profit Alert ({tier})"
        msg["From"] = self.sender
        msg["To"] = email

        try:
            with smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=10) as server:
                server.starttls()
                # Credentials must be injected at runtime, never stored in repo.
                # server.login(os.getenv("SMTP_USER"), os.getenv("SMTP_PASS"))
                server.send_message(msg)
            status = "sent"
        except Exception as exc:
            status = f"failed: {exc}"

        result = {
            "user_id": user_id,
            "email": email,
            "tier": tier,
            "profit": profit,
            "status": status,
            "timestamp": int(time.time()),
        }

        if self.hyperledger_client:
            self.hyperledger_client.log_notification(result)

        return result


notifier = NotificationEngine()


