import os
import requests
import json

# Configuration
BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"
# Use environment variables
BREVO_API_KEY = os.getenv("BREVO_API_KEY") # User provided key
SENDER_EMAIL = os.getenv("EMAIL_HOST_USER", "echogmh123@gmail.com") # User provided email
APP_NAME = "Mental Health App"
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:8000")

def send_password_reset_email(to_email: str, reset_token: str) -> bool:
    """Send password reset code to user via Brevo HTTP API (Bypasses SMTP Firewalls)"""
    
    # Check if API Key is set
    if not BREVO_API_KEY:
        print("Error: BREVO_API_KEY not set in environment variables.")
        return False
        
    try:
        # Use first 6 characters of token as the code
        reset_code = reset_token[:6].upper()
        
        # HTML Content
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
        
        # Brevo API Payload
        headers = {
            "accept": "application/json",
            "api-key": BREVO_API_KEY,
            "content-type": "application/json"
        }
        
        payload = {
            "sender": {
                "name": APP_NAME,
                "email": SENDER_EMAIL
            },
            "to": [
                {
                    "email": to_email
                }
            ],
            "subject": f"Your {APP_NAME} password reset code",
            "htmlContent": html_content
        }
        
        # Send Request
        response = requests.post(BREVO_API_URL, json=payload, headers=headers)
        
        if response.status_code == 201:
            print(f"Brevo: Email sent successfully to {to_email}")
            return True
        else:
            print(f"Brevo Error {response.status_code}: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error sending email via Brevo: {e}")
        return False
