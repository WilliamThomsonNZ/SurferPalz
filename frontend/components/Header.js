import { useAppContext } from "../context/state";
import { getProviderOrSigner } from "../utils";
import { readifyAddress } from "../utils";
import { useEffect, useState } from "react";
import { STAKING_CONTRACT_ADDRESS, STAKING_ABI } from "../constants";
import { Contract } from "ethers";
import Link from "next/link";
import styles from "../styles/appStyling.module.scss";
export default function Header({ currentPage, tokenBalance }) {
  const userState = useAppContext();
  async function connectWallet() {
    try {
      const signer = await getProviderOrSigner(true);
      const addr = await signer.getAddress();
      userState.updateWalletAddress(addr);
      userState.updateWalletConnected(true);
    } catch (err) {
      console.error(err);
    }
  }
  async function handleConnectWalletClick() {
    if (!userState.walletConnected) {
      connectWallet();
    }
  }

  useEffect(() => {
    handleConnectWalletClick();
  }, []);

  return (
    <header className={styles.header}>
      <div className={styles.navigation}>
        <Link href={"/staking"}>
          <a>Staking</a>
        </Link>
        <Link href={"/"}>
          <a>Mint</a>
        </Link>
      </div>
      <div>
        <button onClick={(e) => handleConnectWalletClick(e)}>
          {userState.userWallet
            ? readifyAddress(userState.userWallet)
            : "Connect Wallet"}
        </button>
      </div>
    </header>
  );
}
