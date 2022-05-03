import nc from "next-connect";
import addresses from "../../whitelistAddress.js";

function onWhitelist(_address) {
  const found = addresses.find((addr) => addr == _address);
  if (found) return true;
  return false;
}

const handler = nc().get((req, res) => {
  try {
    const addr = req.query.address;
    const isOnWhitelist = onWhitelist(addr);
    if (isOnWhitelist) {
      res.json({ code: 200, onWhiteliist: true });
    } else {
      res.json({ code: 200, onWhiteliist: false });
    }
  } catch (err) {
    res.json({ code: 400, message: err.message });
  }
});

export default handler;
