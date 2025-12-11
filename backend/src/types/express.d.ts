import { TokenPayload } from "../utils/tokenUtils.js";

declare global {
  namespace Express {
    interface Request {
      admin?: TokenPayload;
      volunteer?: {
        id: string;
        email?: string | undefined;
        type: "volunteer";
        eventId: string;
      };
    }
  }
}

export {};
