
/**
 * Email Service
 *
 * Sends transactional emails via Gmail SMTP (Nodemailer).
 * Falls back to console logging when SMTP env vars are missing (local dev).
 *
 * Functions:
 *   - sendPasswordResetCode(email, code, firstName): Send styled 6-digit code email
 *
 * Environment Variables:
 *   - SMTP_USER: Gmail address (e.g. noreply@assemblyops.org)
 *   - SMTP_PASS: Gmail App Password (Settings → Security → 2FA → App Passwords)
 *
 * Called by: ../services/authService.ts
 */
import nodemailer from 'nodemailer';
import { logger } from '../utils/logger.js';

const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;

function createTransport() {
  if (!SMTP_USER || !SMTP_PASS) {
    return null;
  }
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS,
    },
  });
}

const transporter = createTransport();

export async function sendPasswordResetCode(
  email: string,
  code: string,
  firstName: string
): Promise<void> {
  if (!transporter) {
    logger.warn('SMTP not configured — logging reset code to console', { email, code });
    return;
  }

  const digits = code.split('').map(d =>
    `<td class="code-chip" style="font-size: 24px; font-weight: 600; color: #1A365D; background-color: #F5F0EA; border: 1px solid #E8E0D6; border-radius: 10px; width: 44px; height: 52px; text-align: center; vertical-align: middle; font-family: -apple-system, BlinkMacSystemFont, 'SF Mono', 'Menlo', monospace; box-shadow: 0 1px 2px rgba(0,0,0,0.06);">${d}</td>`
  ).join('<td style="width: 8px;"></td>');

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="color-scheme" content="light dark">
      <meta name="supported-color-schemes" content="light dark">
      <style>
        :root { color-scheme: light dark; }
        @media (prefers-color-scheme: dark) {
          .email-bg { background-color: #141414 !important; }
          .email-card { background-color: #262626 !important; box-shadow: 0 2px 8px rgba(0,0,0,0.3) !important; }
          .accent-bar { background-color: #2C5282 !important; }
          .wordmark { color: #6B9BD2 !important; }
          .title { color: #FFFFFF !important; }
          .body-text { color: #999999 !important; }
          .code-chip { color: #FFFFFF !important; background-color: #1F1F1F !important; border-color: #3A3A3A !important; box-shadow: 0 1px 2px rgba(0,0,0,0.2) !important; }
          .expires-text { color: #666666 !important; }
          .divider { border-top-color: #333333 !important; }
          .muted-text { color: #666666 !important; }
          .footer-text { color: #4A4A4A !important; }
        }
      </style>
    </head>
    <body style="margin: 0; padding: 0;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="email-bg" style="background-color: #FAF7F2; font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif;">
      <tr>
        <td align="center" style="padding: 48px 24px;">
          <!-- Card -->
          <table role="presentation" width="480" cellpadding="0" cellspacing="0" class="email-card" style="max-width: 480px; width: 100%; background-color: #ffffff; border-radius: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04); overflow: hidden;">
            <!-- Accent Bar -->
            <tr>
              <td class="accent-bar" style="background-color: #1A365D; height: 4px; font-size: 0; line-height: 0;">&nbsp;</td>
            </tr>
            <!-- Content -->
            <tr>
              <td style="padding: 40px 36px 36px;">
                <!-- Wordmark -->
                <p class="wordmark" style="margin: 0 0 32px; font-size: 13px; font-weight: 600; color: #1A365D; letter-spacing: 1.2px; text-transform: uppercase;">AssemblyOps</p>
                <!-- Title -->
                <h1 class="title" style="margin: 0 0 12px; font-size: 28px; font-weight: 700; color: #1A1A1A; letter-spacing: -0.5px;">Reset your password</h1>
                <!-- Body -->
                <p class="body-text" style="margin: 0 0 32px; font-size: 16px; line-height: 1.6; color: #727272;">Hi ${firstName}, enter the verification code below to reset your password.</p>
                <!-- Code Chips -->
                <table role="presentation" cellpadding="0" cellspacing="0" style="margin: 0 auto 12px;">
                  <tr>${digits}</tr>
                </table>
                <p class="expires-text" style="margin: 0 0 32px; font-size: 13px; color: #999999; text-align: center;">Expires in 15 minutes</p>
                <!-- Divider -->
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 24px;"><tr><td class="divider" style="border-top: 1px solid #E8E0D6;"></td></tr></table>
                <!-- Disclaimer -->
                <p class="muted-text" style="margin: 0; font-size: 13px; line-height: 1.6; color: #999999;">If you didn't request this, you can safely ignore this email. Your account is secure.</p>
              </td>
            </tr>
          </table>
          <!-- Footer -->
          <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width: 480px; width: 100%;">
            <tr>
              <td align="center" style="padding: 24px 0 0;">
                <p class="footer-text" style="margin: 0; font-size: 12px; color: #999999;">AssemblyOps</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from: `"AssemblyOps" <${SMTP_USER}>`,
    to: email,
    subject: 'Your password reset code',
    html,
  });
}
