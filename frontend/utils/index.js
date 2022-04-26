import ethers, { providers, Contract } from "ethers";

import Web3Modal from "web3modal";

export async function getProviderOrSigner(needSigner = false) {
  const web3modal = new Web3Modal({
    network: "localhost",
    providerOptions: {},
    disableInjectedProvider: false,
  });
  const provider = await web3modal.connect();
  const web3Provider = new providers.Web3Provider(provider);
  const { chainId } = await web3Provider.getNetwork();
  if (chainId != 31337) {
    window.alert("Change the network to Localhost");
    throw new Error("Change network to rinkeby");
  }
  if (needSigner) {
    const signer = web3Provider.getSigner();
    return signer;
  }
  return web3Provider;
}

export function readifyAddress(addr) {
  const readableAddr = `${addr.slice(0, 4)}...${addr.slice(-4)}`;
  return readableAddr;
}

export async function listTokensOfOwner(contractAddress, abi, address) {
  const provider = await getProviderOrSigner();
  const token = new Contract(contractAddress, abi, provider);
  console.log(token);
  console.error(await token.name(), "tokens owned by", address);

  const sentLogs = await token.queryFilter(
    token.filters.Transfer(address, null)
  );
  const receivedLogs = await token.queryFilter(
    token.filters.Transfer(null, address)
  );

  const logs = sentLogs
    .concat(receivedLogs)
    .sort(
      (a, b) =>
        a.blockNumber - b.blockNumber || a.transactionIndex - b.TransactionIndex
    );

  const owned = new Set();

  for (const log of logs) {
    const { from, to, tokenId } = log.args;

    if (to == address) {
      owned.add(tokenId.toString());
    } else if (from == address) {
      owned.delete(tokenId.toString());
    }
  }
  return owned;
}
