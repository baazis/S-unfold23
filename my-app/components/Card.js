import { Contract, ethers, providers } from "ethers";
import { useEffect, useRef, useState } from "react";
import Web3Modal from "web3modal";
import { formatEther } from "ethers/lib/utils";
import { CONTRACT_ADDRESS, abi } from "../constants";

export const Card = ({ id, img, txt, author, tip }) => {
  const [loading, setLoading] = useState(false);
  const [walletConnected, setWalletConnected] = useState(false);
  const [commentText, setCommentText] = useState("");
  const web3ModalRef = useRef();

  const connectWallet = async () => {
    try {
      await getProviderOrSigner();
      setWalletConnected(true);
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    if (!walletConnected) {
      web3ModalRef.current = new Web3Modal({
        network: "mumbai",
        providerOptions: {},
        disableInjectedProvider: false,
      });

      connectWallet();
    }
  }, [walletConnected]);

  const getProviderOrSigner = async (needSigner = false) => {
    const provider = await web3ModalRef.current.connect();
    const web3Provider = new providers.Web3Provider(provider);

    const { chainId } = await web3Provider.getNetwork();
    if (chainId !== 80001) {
      window.alert("Change the network to Mumbai");
      throw new Error("Change network to Mumbai");
    }

    if (needSigner) {
      const signer = web3Provider.getSigner();
      return signer;
    }
    return web3Provider;
  };

  const getDaoContractInstance = (providerOrSigner) => {
    return new Contract(CONTRACT_ADDRESS, abi, providerOrSigner);
  };

  const buyMeCoffee = async () => {
    try {
      const signer = await getProviderOrSigner(true);
      const contract = getDaoContractInstance(signer);

      const txn = await contract.buyMeCoffee(id);
      setLoading(true);

      console.log(txn);
      setLoading(false);
    } catch (error) {
      console.log(error);
    }
  };

  const commentOnPitch = async () => {
    try {
      if (commentText) {
        const signer = await getProviderOrSigner(true);
        const contract = getDaoContractInstance(signer);

        const txn = await contract.commentPitch(id, commentText);
        console.log(txn);

        // Clear the comment text after posting.
        setCommentText("");
      }
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div className="max-w-sm bg-gradient-to-b from-blue-900 to-black rounded-lg border border-gray-200 shadow-md">
      <img className="rounded-t-lg" src={`https://${img}.ipfs.w3s.link`} />
      <div className="px-3 h-30">
        <p className="text-base">{txt}</p>
      </div>
      <div className="pt-4 mb-3 flex justify-center items-center">
        <button
          className="p-1 w-24 items-center text-gray-50 text-sm bg-gradient-to-r from-indigo-900 to-violet-600 rounded-md shadow-lg"
          onClick={buyMeCoffee}
        >
          Tip
        </button>
        <button
          className="p-1 w-24 items-center text-gray-50 text-sm bg-gradient-to-r from-indigo-900 to-violet-600 rounded-md shadow-lg"
          onClick={commentOnPitch}
        >
          Comment
        </button>
        <input
          type="text"
          placeholder="Add a comment..."
          value={commentText}
          onChange={(e) => setCommentText(e.target.value)}
          className="p-1 bg-gray-50 text-black text-sm rounded-md shadow-lg"
        />
      </div>
    </div>
  );
};
