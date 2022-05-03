import nc from "next-connect";
import addresses from "../../whitelistAddress.js";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256";

function generateRoot() {
  const leaves = addresses.map((addr) => keccak256(addr));
  const tree = new MerkleTree(leaves, keccak256);
  const root = tree.getRoot().toString("hex");
  return [root, tree];
}

function generateProof(_address) {
  const [root, tree] = generateRoot();
  const leaf = keccak256(_address);
  const proof = tree.getHexProof(leaf);
  return proof;
}

const handler = nc().get((req, res) => {
  try {
    const addr = req.query.address;
    console.log(addr);
    const proof = generateProof(addr);
    res.json({ code: 200, proof: proof });
  } catch (err) {
    console.log(err);
    res.json({ code: 400, message: err });
  }
});

export default handler;
