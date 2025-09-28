import type { Address } from "viem";
import { readContract, simulateContract, writeContract, waitForTransactionReceipt } from "wagmi/actions";
import { config } from "./wagmi";

const ERC20_ABI = [
  { "name":"balanceOf","type":"function","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },
  { "name":"allowance","type":"function","stateMutability":"view","inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"outputs":[{"name":"","type":"uint256"}] },
  { "name":"approve","type":"function","stateMutability":"nonpayable","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"","type":"bool"}] },
] as const;

export async function erc20BalanceOf(token: Address, owner: Address) {
  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "balanceOf", args: [owner] });
}
export async function erc20Allowance(token: Address, owner: Address, spender: Address) {
  return readContract(config, { address: token, abi: ERC20_ABI, functionName: "allowance", args: [owner, spender] });
}
export async function erc20Approve(token: Address, spender: Address, amount: bigint) {
  const { request } = await simulateContract(config, { address: token, abi: ERC20_ABI, functionName: "approve", args: [spender, amount] });
  const hash = await writeContract(config, request);
  return waitForTransactionReceipt(config, { hash });
}