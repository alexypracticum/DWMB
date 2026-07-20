"""
RBAC plugin — Role-Based Access Control.

Provides role/permission management and access control.
"""
from plugins.base import PluginBase


class RBACPlugin(PluginBase):
    name = "rbac"
    description = "Role-Based Access Control: roles, permissions, access control"
    version = "0.1.0"

    def register(self, app):
        # RBAC service is imported by other modules (auth, routes)
        # No additional routers needed — RBAC is integrated into core auth
        pass


plugin = RBACPlugin()
