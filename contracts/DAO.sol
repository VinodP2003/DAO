// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IFakeNFTMarketplace {

    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns(uint256);

    function available(uint256 _tokenId) external view returns(bool);
    
}

interface INFTColelction {

    function balanceOf(address owner) external view returns(uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
    
}




contract DAO is ERC20,Ownable(msg.sender){
    enum Vote{
        YAY,
        NAY
    }

    struct Proposal{

        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;


    IFakeNFTMarketplace nftMarketplace;
    INFTColelction nftCollection;

    constructor (address _nftMarketplace, address _nftCollection) payable  ERC20("DAO Token", "DAO") {
        _mint(msg.sender, 1000000 * 10**decimals());
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        nftCollection = INFTColelction(_nftCollection);
    }

    modifier onlyMembers() {
        require(balanceOf(msg.sender) > 0, "Only DAO members can execute this");
        _;
    }

    modifier activeProposalOnly(uint256 proposalId){
        require(proposals[proposalId].deadline > block.timestamp,"Inactive proposal");
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalId){
        require(proposals[proposalId].deadline<=block.timestamp,"Active proposal cant execute while active");
        require(!proposals[proposalId].executed, "Proposal alreaduy executed");
        _;
    }


    // Let create and vote the proposals for only token members
    function createPoposal(uint256 _nftTokenId) external onlyMembers returns(uint256) {
        require(nftMarketplace.available(_nftTokenId),"NFT not for sale");

        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals-1;
    }

    function voteOnProposal(uint256 proposalId,Vote vote)external onlyMembers activeProposalOnly((proposalId)){
        Proposal storage proposal = proposals[proposalId];

        uint256 voterNFTBalance = nftCollection.balanceOf(msg.sender);
        uint256 numVotes;

        for(uint256 i=0;i<voterNFTBalance;i++){
            uint256 tokenId = nftCollection.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId]==false){
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes>0,"Already Voted");
        if(vote == Vote.YAY){
            proposal.yayVotes +=numVotes;
        }
        else{
            proposal.nayVotes +=numVotes;
        }
         
    }
    // executing the proposal
    function executeProposal(uint256 proposalId)external onlyMembers inactiveProposalOnly(proposalId){
        Proposal storage proposal = proposals[proposalId];

        if(proposal.yayVotes > proposal.nayVotes){
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance>=nftPrice,"No Enough funds");
            nftMarketplace.purchase{value : nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;

    }

    function withdrawEther() external onlyOwner{
        payable(owner()).transfer(address(this).balance);

    }

    receive() external payable{}

    fallback() external payable{}

}