// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract FakeNFTMarketplace{
    mapping (uint256 => address) public tokens;

    uint256 nftPrice = 0.01 ether;

    function purchase(uint256 _tokenID)external payable {
        require(msg.value >= nftPrice , "NOT_ENOUGH_ETH");
        require(tokens[_tokenID]==address(0), "Token not availabe");
        tokens[_tokenID] = msg.sender;
    }

    function getPrice() external view returns(uint256){
        return nftPrice;
    }

    function available(uint256 _tokenId)external view returns(bool) {
        if(tokens[_tokenId] == address(0)){
            return true;
        }

        return false;

    }
}