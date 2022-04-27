// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
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

    struct StakedItem {
        address owner;
        uint256 stakeType;
        uint256 timeOfStaking;
    }
    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);

    mapping(address => Staker) public stakers;
    mapping(uint256 => StakedItem) public tokens;

    constructor(address _gameToken, address _gameItem) {
        gameItem = GameItem(_gameItem);
        token = GameToken(_gameToken);
    }

    function calculateRewards(address _user) internal returns (uint256) {
        Staker storage staker = stakers[_user];
        for (uint256 index = 0; index < staker.stakedTokens.length; index++) {
            uint256 tokenId = staker.stakedTokens[index];
            StakedItem storage item = tokens[tokenId];
            uint256 claimableTokens = ((block.timestamp - staker.lastUpdate) /
                1) * item.stakeType;
            if (claimableTokens > 0) {
                staker.tokenBalance += claimableTokens;
            }
        }
        return staker.tokenBalance;
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

    function stakeMultiple(uint256[] calldata _tokenIds, uint256 _stakeType)
        external
    {
        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            if (gameItem.ownerOf(tokenId) == msg.sender) {
                _stake(tokenId, msg.sender, _stakeType);
            }
        }
    }

    function stake(uint256 _tokenId, uint256 _stakeType) external {
        require(gameItem.ownerOf(_tokenId) == msg.sender, "Not owner of token");
        _stake(_tokenId, msg.sender, _stakeType);
    }

    function _stake(
        uint256 _tokenId,
        address _user,
        uint256 _stakeType
    ) internal {
        Staker storage staker = stakers[_user];
        require(staker.tokenIndex[_tokenId] == 0, "Token already staked");
        if (staker.stakedTokens.length > 1) {
            calculateRewards(_user);
        }
        staker.stakedTokens.push(_tokenId);
        staker.tokenIndex[_tokenId] = staker.stakedTokens.length - 1;
        staker.lastUpdate = block.timestamp;

        StakedItem storage item = tokens[_tokenId];
        item.owner = _user;
        item.timeOfStaking = block.timestamp;
        item.stakeType = _stakeType;

        gameItem.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit NFTStaked(_user, _tokenId);
    }

    function _unstake(uint256 _tokenId, address _user) internal {
        Staker storage staker = stakers[_user];
        StakedItem storage stakedItem = tokens[_tokenId];
        require(
            block.timestamp - stakedItem.timeOfStaking > 2 minutes,
            "TOKEN_NOT_READY_TO_BE_UNSTAKED"
        );

        uint256 lastIndex = staker.stakedTokens.length - 1;
        uint256 lastIndexKey = staker.stakedTokens[lastIndex];
        uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

        staker.stakedTokens[tokenIdIndex] = lastIndexKey;
        staker.tokenIndex[lastIndexKey] = tokenIdIndex;
        if (staker.stakedTokens.length > 0) {
            staker.stakedTokens.pop();
            delete staker.tokenIndex[_tokenId];
        }
        if (staker.stakedTokens.length < 0) {
            delete stakers[_user];
        }
        delete tokens[_tokenId];

        gameItem.safeTransferFrom(address(this), _user, _tokenId);

        emit NFTUnstaked(_user, _tokenId);
    }

    function unstake(uint256 _tokenId) external {
        StakedItem storage item = tokens[_tokenId];
        require(msg.sender == item.owner, "Not token owner");
        claimTokens();
        _unstake(_tokenId, msg.sender);
    }

    function unstakeMultiple(uint256[] calldata _tokenIds) external {
        console.log(_tokenIds);
        claimTokens();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            console.log(tokenId);
            StakedItem storage item = tokens[tokenId];
            if (item.owner == msg.sender) {
                _unstake(tokenId, msg.sender);
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
