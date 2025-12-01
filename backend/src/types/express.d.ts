import { TokenPayload } from "../utils/tokenUtils.js";

declare global {
  namespace Express {
    interface Request {
      admin?: TokenPayload;
    }
  }
}

export {};
