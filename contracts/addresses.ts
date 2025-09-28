export const RSTOKEN: Record<number, `0x${string}` | undefined> = {
  56: process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_MAINNET as `0x${string}` | undefined,
  97: process.env.NEXT_PUBLIC_RSTOKEN_ADDRESS_TESTNET as `0x${string}` | undefined
};
export const RSTOKEN_DECIMALS = 18;
