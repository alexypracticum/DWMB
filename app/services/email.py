"""
Email service — async email sending via SMTP.

Provides:
- send_email(to, subject, html_body) — send HTML email
- send_verification_email(to, token) — send email verification
- send_password_reset_email(to, token) — send password reset
"""
import logging
from typing import Optional

logger = logging.getLogger(__name__)


async def send_email(
    to: str,
    subject: str,
    html_body: str,
    from_addr: Optional[str] = None,
) -> bool:
    """
    Send an HTML email via SMTP.

    Returns True on success, False on failure.
    Silently fails if SMTP is not configured.
    """
    from app.config import get_settings
    settings = get_settings()

    if not settings.SMTP_HOST:
        logger.debug("SMTP not configured, skipping email to %s", to)
        return False

    try:
        import aiosmtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart

        msg = MIMEMultipart("alternative")
        msg["From"] = from_addr or settings.SMTP_FROM
        msg["To"] = to
        msg["Subject"] = subject

        html_part = MIMEText(html_body, "html", "utf-8")
        msg.attach(html_part)

        await aiosmtplib.send(
            msg,
            hostname=settings.SMTP_HOST,
            port=settings.SMTP_PORT,
            username=settings.SMTP_USER or None,
            password=settings.SMTP_PASSWORD or None,
            use_tls=settings.SMTP_TLS,
        )
        logger.info("Email sent to %s: %s", to, subject)
        return True
    except Exception as e:
        logger.error("Failed to send email to %s: %s", to, e)
        return False


async def send_verification_email(to: str, token: str, base_url: str = "http://localhost:8000") -> bool:
    """Send email verification link."""
    verify_url = f"{base_url}/auth/verify?token={token}"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #3b82f6;">Подтверждение регистрации</h2>
        <p>Для подтверждения вашего email перейдите по ссылке:</p>
        <p style="text-align: center; margin: 30px 0;">
            <a href="{verify_url}" style="background: #3b82f6; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">
                Подтвердить email
            </a>
        </p>
        <p style="color: #6b7280; font-size: 12px;">Если вы не регистрировались, проигнорируйте это письмо.</p>
    </div>
    """
    return await send_email(to, "Подтверждение регистрации — DWMB", html_body)


async def send_password_reset_email(to: str, token: str, base_url: str = "http://localhost:8000") -> bool:
    """Send password reset link."""
    reset_url = f"{base_url}/auth/reset-password?token={token}"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #ef4444;">Сброс пароля</h2>
        <p>Для сброса пароля перейдите по ссылке:</p>
        <p style="text-align: center; margin: 30px 0;">
            <a href="{reset_url}" style="background: #ef4444; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">
                Сбросить пароль
            </a>
        </p>
        <p style="color: #6b7280; font-size: 12px;">Ссылка действительна 1 час. Если вы не запрашивали сброс, проигнорируйте это письмо.</p>
    </div>
    """
    return await send_email(to, "Сброс пароля — DWMB", html_body)
