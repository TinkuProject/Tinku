import { Resend } from "resend";

type AuthCodePurpose = "email_verification" | "password_recovery" | "email_change";

export class EmailService {
  private static client: Resend | null = null;

  private static getClient(): Resend {
    if (this.client) return this.client;

    const apiKey = process.env.RESEND_API_KEY?.trim();
    const fromEmail = process.env.RESEND_FROM_EMAIL?.trim();

    if (!apiKey || !fromEmail) {
      throw new Error("Email service is not configured");
    }

    this.client = new Resend(apiKey);
    return this.client;
  }

  static async sendAuthCode(input: {
    email: string;
    code: string;
    purpose: AuthCodePurpose;
    expiresInMinutes: number;
  }): Promise<void> {
    const verification = input.purpose !== "password_recovery";
    const subject = verification
      ? "Verificá tu correo en Tinku"
      : "Recuperá tu contraseña de Tinku";
    const action = verification
      ? "verificar tu correo"
      : "restablecer tu contraseña";
    const fromName = process.env.RESEND_FROM_NAME?.trim() || "Tinku";
    const fromEmail = process.env.RESEND_FROM_EMAIL?.trim();
    if (!fromEmail) throw new Error("Email service is not configured");

    const { error } = await this.getClient().emails.send({
      from: `${fromName.replace(/[<>"\r\n]/g, "")} <${fromEmail}>`,
      to: input.email,
      subject,
      text: `Tu código para ${action} es ${input.code}. Vence en ${input.expiresInMinutes} minutos. Si no solicitaste este código, ignorá este correo.`,
      html: `
        <div style="font-family:Arial,sans-serif;color:#102a43;max-width:520px;margin:auto">
          <h2 style="color:#0b4f8a">Tinku</h2>
          <p>Usá este código para ${action}:</p>
          <p style="font-size:30px;font-weight:700;letter-spacing:8px;color:#0b4f8a">${input.code}</p>
          <p>Vence en ${input.expiresInMinutes} minutos.</p>
          <p style="color:#627d98;font-size:13px">Si no solicitaste este código, podés ignorar el correo.</p>
        </div>
      `,
    });

    if (error) {
      throw new Error(`Email delivery failed: ${error.message}`);
    }
  }
}
