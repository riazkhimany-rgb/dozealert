<%
' =============================================================================
' DozeAlert feedback — copy this file to config.asp and fill in real values.
' config.asp is gitignored. Never commit secrets.
' =============================================================================

' --- AWS SES SMTP ---
' Create SMTP credentials in AWS SES (not your IAM access key).
' Verify MAIL_FROM (and MAIL_TO if still in sandbox) in SES.
Const SMTP_HOST = "email-smtp.us-east-1.amazonaws.com"
Const SMTP_PORT = 587
Const SMTP_USERNAME = "YOUR_SES_SMTP_USERNAME"
Const SMTP_PASSWORD = "YOUR_SES_SMTP_PASSWORD"
' True = TLS/SSL (recommended for SES). If 587 fails on your IIS host, try SMTP_PORT = 465.
Const SMTP_USE_SSL = True
Const SMTP_TIMEOUT_SECONDS = 60

Const MAIL_FROM = "noreply@dozealert.app"
Const MAIL_FROM_NAME = "DozeAlert Feedback"
Const MAIL_TO = "support@dozealert.app"
Const MAIL_SUBJECT_PREFIX = "[DozeAlert Feedback]"

' --- Google reCAPTCHA v2 ("I'm not a robot" checkbox) ---
' Create keys at https://www.google.com/recaptcha/admin (reCAPTCHA v2 Checkbox)
Const RECAPTCHA_SITE_KEY = "YOUR_RECAPTCHA_SITE_KEY"
Const RECAPTCHA_SECRET_KEY = "YOUR_RECAPTCHA_SECRET_KEY"

' --- Upload / spam limits ---
Const MAX_SCREENSHOTS = 3
Const MAX_SCREENSHOT_BYTES = 5242880
Const ALLOWED_SCREENSHOT_TYPES = "image/jpeg,image/png,image/webp,image/gif"
%>
