import { useAppContext } from "../context/state";
import { getProviderOrSigner } from "../utils";
import { readifyAddress } from "../utils";
import { useEffect, useState } from "react";
import {
  NFT_CONTRACT_ADDRESS,
  NFT_ABI,
  STAKING_CONTRACT_ADDRESS,
} from "../constants";
import { Contract } from "ethers";
import Link from "next/link";
import styles from "../styles/appStyling.module.scss";
export default function Header({ currentPage, tokenBalance }) {
  const userState = useAppContext();
  async function connectWallet() {
    //Display the two options here
    //-- wallet connect
    //--
    try {
      const signer = await getProviderOrSigner(true);
      const addr = await signer.getAddress();
      const contract = new Contract(NFT_CONTRACT_ADDRESS, NFT_ABI, signer);
      const isApproved = await contract.isApprovedForAll(
        addr,
        STAKING_CONTRACT_ADDRESS
      );
      userState.updateUserApproval(isApproved);
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
