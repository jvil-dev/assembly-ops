import { prisma } from "../config/database.js";
import { hashPassword } from "../utils/passwordUtils.js";

interface RegisterAdminInput {
  email: string;
  password: string;
  name: string;
  congregation: string;
}

interface AdminResponse {
  id: string;
  email: string;
  name: string;
  congregation: string;
  createdAt: Date;
  updatedAt: Date;
}

export async function registerAdmin(
  input: RegisterAdminInput
): Promise<AdminResponse> {
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

  // Return admin without password hash
  const { passwordHash: _, ...adminWithoutPassword } = admin;
  return adminWithoutPassword;
}
