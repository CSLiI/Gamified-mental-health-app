import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Configuration
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465  # SSL Port
# Use environment variables for security
SENDER_EMAIL = os.getenv("EMAIL_HOST_USER")
SENDER_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
APP_NAME = "Mental Health App"
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:8000")


def send_password_reset_email(to_email: str, reset_token: str) -> bool:
    """Send password reset code to user via Gmail SMTP"""
    if not SENDER_EMAIL or not SENDER_PASSWORD:
        print("Error: EMAIL_HOST_USER or EMAIL_HOST_PASSWORD not set in environment variables.")
        return False

    try:
        # Use first 6 characters of token as the code
        reset_code = reset_token[:6].upper()
        
        msg = MIMEMultipart()
        msg['From'] = f"{APP_NAME} <{SENDER_EMAIL}>"
        msg['To'] = to_email
        msg['Subject'] = f"Your {APP_NAME} password reset code"

        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #6C5CE7 0%, #667EEA 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f8f9fe; padding: 30px; border-radius: 0 0 10px 10px; }}
                .code-box {{ background: white; border: 3px dashed #6C5CE7; border-radius: 12px; padding: 30px; text-align: center; margin: 20px 0; }}
                .code {{ font-size: 48px; font-weight: bold; color: #6C5CE7; letter-spacing: 8px; font-family: monospace; }}
                .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Password Reset Code 🔐</h1>
                </div>
                <div class="content">
                    <h2>Reset Your Password</h2>
                    <p>We received a request to reset your password. Use the code below in the app:</p>
                    
                    <div class="code-box">
                        <p style="margin: 0; font-size: 14px; color: #666;">Your verification code:</p>
                        <div class="code">{reset_code}</div>
                    </div>
                    
                    <p style="text-align: center; color: #666; font-size: 14px;">
                        Enter this code in the app to reset your password
                    </p>
                    
                    <div class="warning">
                        <strong>⚠️ Security Notice:</strong><br>
                        This code will expire in 1 hour. If you didn't request a password reset, please ignore this email and your password will remain unchanged.
                    </div>
                </div>
                <div class="footer">
                    <p>© 2024 {APP_NAME}. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html_content, 'html'))

        # Connect to Gmail SMTP Server using SSL
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(msg)
            
        return True
    except Exception as e:
        print(f"Error sending password reset email: {e}")
        return False
