import { describe, it, expect } from "vitest";
import { calcMinReceived } from "@/lib/math";

describe("calcMinReceived", () => {
  it("works with zero bps", () => { expect(calcMinReceived(100, 0)).toBe(100); });
  it("works with 50 bps", () => { expect(calcMinReceived(100, 50)).toBe(99.5); });
});
