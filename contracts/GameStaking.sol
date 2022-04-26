// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GameToken.sol";
import "./GameItem.sol";
import "hardhat/console.sol";

contract ItemStake {
    GameItem gameItem;
    GameToken token;

    struct Staker {
        uint256[] stakedTokens;
        mapping(uint256 => uint256) tokenIndex;
        uint256 lastUpdate;
        uint256 tokenBalance;
    }
    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);
    //mapping(uint256 => s) public stakedItems;
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwners;

    constructor(address _gameToken, address _gameItem) {
        gameItem = GameItem(_gameItem);
        token = GameToken(_gameToken);
    }

    function calculateRewards(address _user) internal returns (uint256) {
        Staker storage staker = stakers[_user];
        uint256 claimableAmountPerToken = (block.timestamp -
            staker.lastUpdate) / 1;
        uint256 tokensToClaim = staker.stakedTokens.length *
            claimableAmountPerToken;
        if (tokensToClaim > 0) {
            staker.tokenBalance += tokensToClaim;
            return tokensToClaim;
        }
        return 0;
    }

    function getClaimableTokens() external returns (uint256) {
        Staker storage staker = stakers[msg.sender];
        calculateRewards(msg.sender);
        uint256 tokens = staker.tokenBalance;
        return tokens;
    }

    function claimTokens() public {
        Staker storage staker = stakers[msg.sender];
        uint256 claimableTokens = calculateRewards(msg.sender);
        if (staker.tokenBalance > 0) {
            staker.tokenBalance = 0;
            staker.lastUpdate = block.timestamp;
            token.mint(msg.sender, claimableTokens * (10**18));
        }
    }

    function stakeMultiple(uint256[] calldata _tokenIds) external {
        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            if (gameItem.ownerOf(tokenId) == msg.sender) {
                _stake(tokenId, msg.sender);
            }
        }
    }

    function stake(uint256 _tokenId) external {
        require(gameItem.ownerOf(_tokenId) == msg.sender, "Not owner of token");
        _stake(_tokenId, msg.sender);
    }

    function _stake(uint256 _tokenId, address _user) internal {
        Staker storage staker = stakers[_user];
        require(staker.tokenIndex[_tokenId] == 0, "Token already staked");
        if (staker.stakedTokens.length > 1) {
            calculateRewards(_user);
        }
        staker.stakedTokens.push(_tokenId);
        staker.tokenIndex[staker.stakedTokens.length - 1];
        staker.lastUpdate = block.timestamp;
        gameItem.safeTransferFrom(msg.sender, address(this), _tokenId);
        tokenOwners[_tokenId] = _user;
        emit NFTStaked(_user, _tokenId);
    }

    function _unstake(uint256 _tokenId, address _user) internal {
        Staker storage staker = stakers[_user];

        uint256 lastIndex = staker.stakedTokens.length - 1;
        uint256 lastIndexKey = staker.stakedTokens[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

        staker.stakedTokens[tokenIdIndex] = lastIndexKey;
        //staker.tokenIndex[lastIndexKey] = tokenIdIndex;

        if (staker.stakedTokens.length > 0) {
            staker.stakedTokens.pop();
            delete staker.tokenIndex[_tokenId];
        }
        if (staker.stakedTokens.length < 0) {
            delete stakers[_user];
        }
        delete tokenOwners[_tokenId];

        gameItem.safeTransferFrom(address(this), _user, _tokenId);

        emit NFTUnstaked(_user, _tokenId);
    }

    function unstake(uint256 _tokenId) external {
        require(msg.sender == tokenOwners[_tokenId], "Not token owner");
        claimTokens();
        _unstake(_tokenId, msg.sender);
    }

    function unstakeMultiple(uint256[] calldata _tokenIds) external {
        claimTokens();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (tokenOwners[_tokenIds[i]] == msg.sender) {
                _unstake(_tokenIds[i], msg.sender);
            }
        }
    }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory)
    {
        Staker storage staker = stakers[_user];
        return staker.stakedTokens;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}
