// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GameItem is ERC721AQueryable, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;
    //Chainlink Subscription Credentials
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionId;
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint256[] public s_randomWords;
    uint256 public requestId;

    //NFT collection details
    uint256 public maxTotalSupply = 444;
    uint256 public mintPrice = 0.01 ether;
    uint256 public maxMintPerTx = 2;
    string private baseURI;
    bytes32 private whitelistMerkleRoot;

    //Contract state
    bool public paused = false;

    mapping(uint256 => uint256) public surferStatsById;
    mapping(uint256 => address) internal requestToSender;
    mapping(address => bool) private whitelistUsed;

    constructor(uint64 _subscriptionId, bytes32 _keyHash)
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721A("SurferPalz", " SP")
    {
        keyHash = _keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        subscriptionId = _subscriptionId;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Surfer Palz cannot be called by a contract"
        );
        _;
    }

    function fulfillRandomWords(
        uint256 requestedId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        uint256 currentTokenId = _currentIndex;
        uint256[] memory stats = new uint256[](4);

        stats[0] = 0;
        stats[1] = 4;
        stats[2] = 8;
        stats[3] = 12;

        for (uint256 index = 0; index < s_randomWords.length; index++) {
            uint256 randomNumber = s_randomWords[index];
            uint256[] memory statValues = new uint256[](4);

            statValues[0] = (randomNumber & 0xF);
            statValues[1] = ((randomNumber >> 4) & 0xF);
            statValues[2] = ((randomNumber >> 8) & 0xF);
            statValues[3] = ((randomNumber >> 12) & 0xF);

            uint256 surferStats;
            uint256 len = 4;

            do {
                len--;
                surferStats |= statValues[len] << stats[len];
            } while (len > 0);

            surferStatsById[currentTokenId] = surferStats;
            currentTokenId++;
        }
        _safeMint(requestToSender[requestedId], s_randomWords.length);
    }

    function whitelistMint(bytes32[] calldata _proof, uint256 _amount)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(whitelistUsed[msg.sender] == false, "WHITELIST_ALREADY_USED");
        require(
            MerkleProof.verify(_proof, whitelistMerkleRoot, leaf),
            "NOT_ON_WHITELIST"
        );
        require(_amount <= maxMintPerTx, "2_PER_TX_MAX");
        require(!paused, "MINTING_IS_PAUSED");
        require(
            _amount + _currentIndex <= maxTotalSupply,
            "MAX_SUPPLY_REACHED"
        );
        require(msg.value >= _amount * mintPrice, "INCORRECT_ETH_AMOUNT");
        whitelistUsed[msg.sender] = true;
        _safeMint(msg.sender, _amount);

        // requestId = COORDINATOR.requestRandomWords(
        //     keyHash,
        //     subscriptionId,
        //     requestConfirmations,
        //     callbackGasLimit,
        //     uint32(_amount)
        // );
        //requestToSender[requestId] = msg.sender;
    }

    function mint(uint32 _amount) public payable callerIsUser {
        require(_amount <= maxMintPerTx, "2_PER_TX_MAX");
        require(!paused, "MINTING_IS_PAUSED");
        require(
            _amount + _currentIndex <= maxTotalSupply,
            "MAX_SUPPLY_REACHED"
        );
        require(msg.value == _amount * mintPrice, "INCORRECT_ETH_AMOUNT");
        // requestId = COORDINATOR.requestRandomWords(
        //     keyHash,
        //     subscriptionId,
        //     requestConfirmations,
        //     callbackGasLimit,
        //     _amount
        // );
        // requestToSender[requestId] = msg.sender;
        _safeMint(msg.sender, _amount);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setContractPaused(bool _val) public onlyOwner {
        paused = _val;
    }

    //Functionality for returning surfer stats
    function getSpeed(uint256 _tokenId) public view returns (uint256) {
        uint256 stats = surferStatsById[_tokenId];
        uint256 speed = (stats & 0xF);
        return speed;
    }

    function getFlow(uint256 _tokenId) public view returns (uint256) {
        uint256 stats = surferStatsById[_tokenId];
        uint256 speed = ((stats >> 4) & 0xF);
        return speed;
    }

    function getStyle(uint256 _tokenId) public view returns (uint256) {
        uint256 stats = surferStatsById[_tokenId];
        uint256 speed = ((stats >> 8) & 0xF);
        return speed;
    }

    function getPower(uint256 _tokenId) public view returns (uint256) {
        uint256 stats = surferStatsById[_tokenId];
        uint256 speed = ((stats >> 12) & 0xF);
        return speed;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
}
