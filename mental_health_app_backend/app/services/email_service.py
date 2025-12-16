import os
import resend
from typing import Optional

# Initialize Resend with API key
resend.api_key = os.getenv("RESEND_API_KEY", "re_UTYcSmbe_6eZAqDhgsGwvJJXcYTxE6V8r")

# Your app's sender email (must be verified in Resend dashboard)
SENDER_EMAIL = "onboarding@resend.dev"  # Use Resend's test domain for now
APP_NAME = "Mental Health App"
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:8000")


def send_password_reset_email(to_email: str, reset_token: str) -> bool:
    """Send password reset link to user"""
    try:
        reset_url = f"{FRONTEND_URL}/reset-password?token={reset_token}"
        
        params = {
            "from": f"{APP_NAME} <{SENDER_EMAIL}>",
            "to": [to_email],
            "subject": f"Reset your {APP_NAME} password",
            "html": f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background: linear-gradient(135deg, #6C5CE7 0%, #667EEA 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                    .content {{ background: #f8f9fe; padding: 30px; border-radius: 0 0 10px 10px; }}
                    .button {{ display: inline-block; padding: 15px 30px; background: #6C5CE7; color: white; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: bold; }}
                    .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }}
                    .footer {{ text-align: center; margin-top: 20px; color: #666; font-size: 12px; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Password Reset Request 🔐</h1>
                    </div>
                    <div class="content">
                        <h2>Reset Your Password</h2>
                        <p>We received a request to reset your password. Click the button below to create a new password:</p>
                        <p style="text-align: center;">
                            <a href="{reset_url}" class="button">Reset Password</a>
                        </p>
                        <p>Or copy and paste this link into your browser:</p>
                        <p style="word-break: break-all; color: #6C5CE7;">{reset_url}</p>
                        <div class="warning">
                            <strong>⚠️ Security Notice:</strong><br>
                            This link will expire in 1 hour. If you didn't request a password reset, please ignore this email and your password will remain unchanged.
                        </div>
                    </div>
                    <div class="footer">
                        <p>© 2024 {APP_NAME}. All rights reserved.</p>
                    </div>
                </div>
            </body>
            </html>
            """
        }
        
        email = resend.Emails.send(params)
        return True
    except Exception as e:
        print(f"Error sending password reset email: {e}")
        return False
