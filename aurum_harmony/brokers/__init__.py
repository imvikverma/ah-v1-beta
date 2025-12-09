"""
Broker management package.
"""

from .routes import brokers_bp

# Import individual broker blueprints
try:
    from .kotak_neo import kotak_bp
except ImportError:
    kotak_bp = None

try:
    from .hdfc_sky import hdfc_bp
except ImportError:
    hdfc_bp = None

__all__ = ['brokers_bp', 'kotak_bp', 'hdfc_bp']

