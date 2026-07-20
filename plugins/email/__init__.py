"""
Email plugin — async email sending via SMTP.

Provides email verification, password reset, and notification emails.
"""
from plugins.base import PluginBase


class EmailPlugin(PluginBase):
    name = "email"
    description = "Email notifications: verification, password reset, alerts"
    version = "0.1.0"

    def register(self, app):
        # Email service is imported by auth routes
        # No additional routers needed — email is integrated into auth
        pass


plugin = EmailPlugin()
