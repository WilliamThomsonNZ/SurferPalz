import styles from "../styles/appStyling.module.scss";
import { Contract, utils } from "ethers";
import { useEffect, useState } from "react";
import Web3Modal from "web3modal";
import { useAppContext } from "../context/state";
import Header from "../components/Header";
import { NFT_CONTRACT_ADDRESS, NFT_ABI } from "../constants";
import { getProviderOrSigner } from "../utils";
export default function Home() {
  const userState = useAppContext();
  const [amountToMint, setAmountToMint] = useState(0);
  const [loading, setLoading] = useState(false);
  async function handleMint() {
    if (!userState.userWallet) {
      return;
    }
    if (loading) return;
    setLoading(true);
    const mintPrice = 0.01;
    try {
      const signer = await getProviderOrSigner(true);
      const contract = new Contract(NFT_CONTRACT_ADDRESS, NFT_ABI, signer);
      const mintValue = String(amountToMint * mintPrice);
      const tx = await contract.mint(amountToMint, {
        value: utils.parseEther(mintValue),
      });
      await tx.wait();
      setLoading(false);
    } catch (err) {
      console.error(err);
      let errorMessage;
      switch (err.code) {
        case "INSUFFICIENT_FUNDS":
          errorMessage = "Insufficient funds.";
          break;
        default:
          errorMessage =
            "An error occured and the transaction was not processed.";
          break;
      }
      setLoading(false);
    }
  }

  async function checkOnWhitelist(_address) {
    const response = await fetch(`/api/whitelist?address=${_address}`);
    const json = await response.json();
    return json.onWhitelist;
  }

  async function handleWhitelistMint() {
    if (!userState.userWallet) {
      return;
    }
    if (loading) return;
    const addr = "0x99E48f65f57b7b4C6f253eFfC5429192F0916215";
    setLoading(true);
    const onWhitelist = await checkOnWhitelist(addr);
    if (onWhitelist) {
      try {
        const signer = await getProviderOrSigner(true);
        const contract = new Contract(NFT_CONTRACT_ADDRESS, NFT_ABI, signer);
        const mintValue = String(amountToMint * mintPrice);
        const tx = await contract.whitelistMint(amountToMint, {
          value: utils.parseEther(mintValue),
        });
        await tx.wait();
        setLoading(false);
      } catch (err) {
        console.error(err);
        let errorMessage;
        switch (err.code) {
          case "INSUFFICIENT_FUNDS":
            errorMessage = "Insufficient funds.";
            break;
          default:
            errorMessage =
              "An error occured and the transaction was not processed.";
            break;
        }
      }
    }
    setLoading(false);
  }
  return (
    <div className={styles.container}>
      <Header />
      <main className={styles.main}>
        <input
          type="number"
          max={10}
          min={0}
          onChange={(e) => setAmountToMint(e.target.value)}
          value={amountToMint}
        />
        <button onClick={() => handleMint()}>Mint</button>
        <button onClick={() => handleWhitelistMint()}>Mint Whitelist</button>
      </main>
    </div>
  );
}
