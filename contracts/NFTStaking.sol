// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./NFTCollection.sol";
import "./StakeRewards.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    uint256 public totalStaked;

    // struct to store a stake's token, owner, and earning values
    struct Stake{
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    // NFT Collection Contract
    NFTCollection nft;
    // Stake Rewards Contract
    StakeRewards token;

    // Vault for Staking
    mapping(uint256 => Stake) public vault;

    uint256 private constant c_dailyRewards = 10000 ether;
    constructor(NFTCollection _nft, StakeRewards _token){
        nft = _nft;
        token = _token;
    }

    function stake(uint256[] calldata tokenIds) external {
       uint256 tokenId;
       totalStaked += tokenIds.length;
       for(uint i=0;i < tokenIds.length; i++){
         tokenId = tokenIds[i];
         require(nft.ownerOf(tokenId) == msg.sender, "Not your NFT");
         require(vault[tokenId].tokenId == 0,"Already staked");

         nft.transferFrom(msg.sender, address(this), tokenId);
         emit NFTStaked(msg.sender, tokenId, block.timestamp);

         vault[tokenId] = Stake({
            owner: msg.sender,
            tokenId: uint24(tokenId),
            timestamp:uint48(block.timestamp)
         });
       } 
    }

    function unstakeMany(address account, uint256[] calldata tokenIds) internal {
         uint256 tokenId;
         totalStaked += tokenIds.length;
         for(uint i=0;i < tokenIds.length; i++){
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender,"Not an Owner");

            delete vault[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
      }
    }

    function claim(uint256[] calldata  tokenIds) external {
      _claim(msg.sender, tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
    }

    function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
         uint256 tokenId;
         uint256 earned = 0;

         for(uint i =0; i< tokenIds.length; i++){
          tokenId = tokenIds[i];
          Stake memory staked = vault[tokenId];
          require(staked.owner == account, "not an owner");
          uint256 stakedAt = staked.timestamp;
          earned += c_dailyRewards * (block.timestamp - stakedAt)/ 1 days;
          vault[tokenId] = Stake({
            owner: account,
            tokenId: uint24(tokenId),
            timestamp:uint48(block.timestamp)
          });
         }

         if(earned > 0){
          earned = earned / c_dailyRewards;
          token.mint(account, earned);
         }

         if(_unstake){
           unstakeMany(account, tokenIds);
         }
         emit Claimed(account, earned);
    }

    function earningInfo(uint256[] calldata tokenIds) external view returns(uint256[2] memory info){
      uint256 tokenId;
      uint256 totalScore =0;
      uint256 earned = 0;
        for(uint i =0; i< tokenIds.length; i++){
          tokenId = tokenIds[i];
          Stake memory staked = vault[tokenId];
          uint256 stakedAt = staked.timestamp;
          earned += c_dailyRewards * (block.timestamp - stakedAt) / 1  days;
        }
      uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
      earnRatePerSecond = earnRatePerSecond / c_dailyRewards;
      return [earned, earnRatePerSecond];
    }

    function balanceOf(address account) public view returns(uint256){
      uint256 balance = 0;
      uint256 supply = nft.totalSupply();
      for(uint i=1; i <= supply; i++){
        if(vault[i].owner == account){
          balance += 1;
        }
      }
      return balance;
    }

    function tokensOfOwner(address account) public view returns(uint256[] memory){
       uint256 supply = nft.totalSupply();

       uint256[] memory tmp = new uint256[](supply);

       uint256 index = 0;
       for(uint tokenIndex =1; tokenIndex <= supply; tokenIndex++){
          if(vault[tokenIndex].owner == account){
            tmp[index] = vault[tokenIndex].tokenId;
            index +=1;
          }
       }

       uint256[] memory tokens = new uint256[](index);
       for(uint i =0; i < index; i++){
        tokens[i]= tmp[i];
       }
       return tokens;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns(bytes4)  {
      require(from==address(0x0), "Cannot send NFTs to vault directly");
      return IERC721Receiver.onERC721Received.selector;

    }
}