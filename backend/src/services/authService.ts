import { prisma } from "../config/database.js";
import { comparePassword, hashPassword } from "../utils/passwordUtils.js";
import { generateToken, TokenPayload } from "../utils/tokenUtils.js";

// ============================================
// ADMIN AUTHENTICATION
// ============================================

interface RegisterAdminInput {
  email: string;
  password: string;
  name: string;
  congregation: string;
}

interface LoginAdminInput {
  email: string;
  password: string;
}

interface AdminData {
  id: string;
  email: string;
  name: string;
  congregation: string;
  createdAt: Date;
  updatedAt: Date;
}

interface AdminAuthResponse {
  admin: AdminData;
  token: string;
}

// ============================================
// VOLUNTEER AUTHENTICATION
// ============================================

interface LoginVolunteerInput {
  generatedId: string;
  loginToken: string;
}

interface VolunteerData {
  id: string;
  name: string;
  phone: string | null;
  email: string | null;
  congregation: string;
  appointment: string;
  generatedId: string;
  roleId: string | null;
  eventId: string;
  createdAt: Date;
  updatedAt: Date;
  role: {
    id: string;
    name: string;
    displayOrder: number;
  } | null;
  event: {
    id: string;
    name: string;
    type: string;
    location: string;
    startDate: Date;
    endDate: Date;
  };
}

interface VolunteerAuthResponse {
  volunteer: VolunteerData;
  token: string;
}

// ============================================
// ADMIN AUTHENTICATION
// ============================================

export async function registerAdmin(
  input: RegisterAdminInput
): Promise<AdminAuthResponse> {
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

export async function loginAdmin(
  input: LoginAdminInput
): Promise<AdminAuthResponse> {
  const { email, password } = input;

  // Find admin by email
  const admin = await prisma.admin.findUnique({
    where: { email: email.toLowerCase() },
  });

  if (!admin) {
    throw new Error("INVALID_CREDENTIALS");
  }

  // Compare password
  const isValidPassword = await comparePassword(password, admin.passwordHash);

  if (!isValidPassword) {
    throw new Error("INVALID_CREDENTIALS");
  }

  // Generate token
  const tokenPayload: TokenPayload = {
    id: admin.id,
    email: admin.email,
    type: "admin",
  };
  const token = generateToken(tokenPayload);

  // Return admin without password hash + token
  const { passwordHash: _, ...adminWithoutPassword } = admin;
  return {
    admin: adminWithoutPassword,
    token,
  };
}

// ============================================
// VOLUNTEER AUTHENTICATION
// ============================================

export async function loginVolunteer(
  input: LoginVolunteerInput
): Promise<VolunteerAuthResponse> {
  const { generatedId, loginToken } = input;

  const volunteer = await prisma.volunteer.findUnique({
    where: { generatedId: generatedId.toUpperCase() },
    include: {
      role: {
        select: {
          id: true,
          name: true,
          displayOrder: true,
        },
      },
      event: {
        select: {
          id: true,
          name: true,
          type: true,
          location: true,
          startDate: true,
          endDate: true,
        },
      },
    },
  });

  if (!volunteer) {
    throw new Error("INVALID_CREDENTIALS");
  }

  if (volunteer.loginToken !== loginToken) {
    throw new Error("INVALID_CREDENTIALS");
  }

  const tokenPayload: TokenPayload = {
    id: volunteer.id,
    type: "volunteer",
    eventId: volunteer.eventId,
    ...(volunteer.email && { email: volunteer.email }),
  };
  const token = generateToken(tokenPayload);

  const { loginToken: _, ...volunteerWithoutToken } = volunteer;

  return {
    volunteer: volunteerWithoutToken,
    token,
  };
}
