// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DAO {
    struct Proposal {
        string description;
        address proposer;
        bool isAccepted;
        uint256 totalVotes;
        mapping(address => bool) votes;
    }

    address public owner;
    mapping(address => bool) public isBoardMember;
    mapping(address => bool) public isMember;
    uint256 public totalAssetPool;
    Proposal[] public proposals;

    constructor(uint256 initialAssetPool) {
        owner = msg.sender;
        totalAssetPool = initialAssetPool;
    }

    function joinAsBoardMember() external {
        require(!isMember[msg.sender], "Already a regular member");
        require(!isBoardMember[msg.sender], "Already a board member");
        isBoardMember[msg.sender] = true;
    }

    function joinAsRegularMember() external {
        require(!isMember[msg.sender], "Already a regular member");
        require(!isBoardMember[msg.sender], "Already a board member");
        isMember[msg.sender] = true;
    }

    function makeProposal(string calldata description) external {
        require(
            isMember[msg.sender] || isBoardMember[msg.sender],
            "Not a member of DAO"
        );
        proposals.push();
        Proposal storage newProposal = proposals[proposals.length - 1];
        newProposal.description = description;
        newProposal.proposer = msg.sender;
        newProposal.isAccepted = false;
        newProposal.totalVotes = 0;
    }

    function vote(uint256 proposalIndex, bool accept) external {
        require(isBoardMember[msg.sender], "Only board members can vote");
        require(!proposals[proposalIndex].votes[msg.sender], "Already voted");

        proposals[proposalIndex].votes[msg.sender] = true;
        proposals[proposalIndex].totalVotes += 1;

        if (accept) {
            proposals[proposalIndex].isAccepted = true;
        }
    }
}
