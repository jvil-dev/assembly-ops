# Security Policy

## Supported Versions

AssemblyOps is currently in **beta testing** (Phase 7: TestFlight & Beta Prep). Security updates are provided for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of AssemblyOps seriously. If you discover a security vulnerability, please follow these steps:

### 1. Do Not Create a Public Issue

Please **do not** report security vulnerabilities through public GitHub issues, as this could put users at risk.

### 2. Report Privately

Send a detailed report to the project maintainers:

- **Email:** [Create a private security advisory on GitHub](https://github.com/jvil-dev/assembly-ops/security/advisories/new)
- **Alternative:** Contact the repository owner directly through GitHub

### 3. Include in Your Report

Please include as much information as possible:

- **Type of vulnerability** (e.g., SQL injection, XSS, authentication bypass)
- **Full paths of affected source files**
- **Location of the affected code** (tag/branch/commit or direct URL)
- **Step-by-step instructions to reproduce the issue**
- **Proof-of-concept or exploit code** (if available)
- **Impact assessment** (what an attacker could achieve)
- **Suggested remediation** (if you have recommendations)

### 4. Response Timeline

- **Acknowledgment:** Within 48 hours of your report
- **Initial Assessment:** Within 5 business days
- **Fix Timeline:** Critical vulnerabilities will be addressed within 7 days
- **Disclosure:** We follow coordinated disclosure practices

## Security Measures

AssemblyOps implements multiple layers of security:

### Backend API
- **Authentication:** JWT-based authentication with access and refresh tokens
- **Authorization:** Role-based access control (RBAC) for overseers and volunteers
- **Rate Limiting:** Protection against brute-force attacks
- **Input Validation:** Zod schema validation for all GraphQL inputs
- **Query Complexity:** GraphQL query depth limiting
- **Security Headers:** Helmet.js for HTTP security headers
- **CORS:** Configurable Cross-Origin Resource Sharing
- **PII Encryption:** Sensitive data encrypted at rest

### Database
- **Parameterized Queries:** Prisma ORM prevents SQL injection
- **Connection Pooling:** PgBouncer for production database connections
- **Migrations:** Version-controlled schema changes
- **Backups:** Automated daily backups (Supabase managed)

### Infrastructure
- **HTTPS Only:** All traffic encrypted in transit (AWS ALB)
- **Container Security:** Non-root user in Docker containers
- **Environment Variables:** Secrets managed through AWS Secrets Manager
- **Health Checks:** Automated monitoring of service health

### Dependencies
- **Automated Scanning:** npm audit in CI/CD pipeline
- **Regular Updates:** Dependencies reviewed and updated quarterly
- **Known Vulnerabilities:** Zero tolerance for high-severity issues

## Security Best Practices for Users

### For Administrators
1. **Strong Passwords:** Use passwords with at least 12 characters
2. **Unique Secrets:** Generate secure JWT secrets (min 32 characters)
3. **Environment Variables:** Never commit `.env` files to version control
4. **Access Control:** Grant minimum required permissions
5. **Regular Updates:** Keep the application updated to the latest version

### For Developers
1. **Code Review:** All changes require peer review
2. **Testing:** Write security tests for authentication/authorization
3. **Input Validation:** Validate and sanitize all user inputs
4. **Error Handling:** Avoid exposing sensitive information in errors
5. **Logging:** Log security-relevant events (login attempts, permission changes)

## Disclosure Policy

When a security vulnerability is confirmed:

1. We will work on a fix immediately
2. A security advisory will be created on GitHub
3. Affected users will be notified via email (if contact info available)
4. The fix will be released as a patch version
5. Public disclosure will occur after 90% of active installations are patched

## Security Contacts

- **GitHub Security Advisories:** [View advisories](https://github.com/jvil-dev/assembly-ops/security/advisories)
- **Primary Maintainer:** Available through GitHub profile

## Attribution

We appreciate security researchers who responsibly disclose vulnerabilities. With your permission, we will:

- Credit you in the security advisory
- List you in our security acknowledgments
- Provide updates on the fix timeline

Thank you for helping keep AssemblyOps and our users safe!
