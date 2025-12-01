import { prisma } from "../config/database.js";
import { hashPassword } from "../utils/passwordUtils.js";
import { generateToken, TokenPayload } from "../utils/tokenUtils.js";

interface RegisterAdminInput {
  email: string;
  password: string;
  name: string;
  congregation: string;
}

interface AdminData {
  id: string;
  email: string;
  name: string;
  congregation: string;
  createdAt: Date;
  updatedAt: Date;
}

interface AuthResponse {
  admin: AdminData;
  token: string;
}
export async function registerAdmin(
  input: RegisterAdminInput
): Promise<AuthResponse> {
  const { email, password, name, congregation } = input;

  // Check if admin already exists
  const existingAdmin = await prisma.admin.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (existingAdmin) {
    throw new Error("EMAIL_EXISTS");
  }

  // Hash password
  const passwordHash = await hashPassword(password);

  // Create admin
  const admin = await prisma.admin.create({
    data: {
      email: email.toLowerCase(),
      passwordHash,
      name,
      congregation,
    },
  });

  // Generate token (auto-login)
  const tokenPayload: TokenPayload = {
    id: admin.id,
    email: admin.email,
    type: "admin",
  };

  const token = generateToken(tokenPayload);

  // Return admin without password hash
  const { passwordHash: _, ...adminWithoutPassword } = admin;
  return {
    admin: adminWithoutPassword,
    token,
  };
}
