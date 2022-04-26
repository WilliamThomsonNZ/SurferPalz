import { createContext, useContext, useState } from "react";

const AppContext = createContext();

export function AppWrapper({ children }) {
  const [userWallet, setUserWallet] = useState("");
  const [walletConnected, setWalletConnected] = useState(false);
  const [web3Modal, setWeb3Modal] = useState({});

  let userWalletState = {
    updateWalletAddress: (val) => setUserWallet(val),
    updateWalletConnected: (val) => setWalletConnected(val),
    updateWeb3Modal: (val) => setWeb3Modal(val),
    walletConnected,
    userWallet,
    web3Modal,
  };

  return (
    <AppContext.Provider value={userWalletState}>
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext() {
  return useContext(AppContext);
}
