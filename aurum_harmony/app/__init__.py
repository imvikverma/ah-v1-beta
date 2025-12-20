# AurumHarmony app package

from flask import Flask
from .routes import admin_bp

def create_app():
    app = Flask(__name__)
    app.register_blueprint(admin_bp)
    # TODO: Initialize Fabric integration here
    return app 