# AurumHarmony Project Requirements (rules.md)

## General Development Guidelines
- All code must be version-controlled using Git with a central repository on GitHub.
- Weekly code reviews are mandatory, conducted by a senior developer.
- Documentation must accompany all new features, stored in the docs/ directory.

## Coding Standards
- Adhere to PEP 8 for Python, Android Kotlin Coding Conventions, and Swift API Design Guidelines.
- Use consistent naming conventions: camelCase for variables, PascalCase for classes.
- Include inline comments for complex logic and docstrings for functions.

## Security Protocols
- Encrypt sensitive data with AES-256; store keys in environment variables.
- Implement OAuth 2.0 for all API authentications.
- Conduct quarterly penetration testing and address vulnerabilities within 72 hours.

## Compliance Requirements
- Ensure SEBI compliance for all trades, including lot sizes and expiry rules.
- Maintain audit logs for 5 years, accessible via the admin panel.
- Sync tax calculations with government-approved apps, adhering to 18% GST and 39% Income Tax rates.

## Testing and Deployment
- Perform unit tests with pytest, achieving 90% coverage.
- Conduct realistic and edge case testing (see annexures for details) before deployment.
- Use CI/CD pipelines (Jenkins) for automated deployment to AWS/Google Cloud.

## Maintenance and Updates
- Schedule weekly ML model retraining and strategy adjustments.
- Address bugs within 24 hours of reporting, tracked via Jira.
- Perform infrastructure maintenance (e.g., scaling, backups) every 30 days. 