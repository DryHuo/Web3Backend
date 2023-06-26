// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO {
    IERC20 public token;

    struct Proposal {
        string description;
        address proposer;
        bool isAccepted;
        uint256 totalVotes;
        mapping(address => bool) votes;
    }

    address public owner;
    address public taxAccount;
    uint256 public minStake;
    uint256 public constant TAX_RATE = 2; // The fee rate is 2%

    mapping(address => bool) public isBoardMember;
    mapping(address => bool) public isMember;
    uint256 public totalAssetPool;
    Proposal[] public proposals;

    constructor(
        address tokenAddress,
        address _LifeWikiAssetPool,
        uint256 _minStake,
        uint256 initialAssetPool
    ) {
        require(
            initialAssetPool >= _minStake,
            "Initial asset pool must be at least minimum stake"
        );
        token = IERC20(tokenAddress);
        owner = msg.sender;
        taxAccount = _LifeWikiAssetPool;
        minStake = _minStake;
        totalAssetPool = initialAssetPool;
        _transferTokens(msg.sender, address(this), initialAssetPool);
        _transferTokens(
            msg.sender,
            taxAccount,
            (initialAssetPool * TAX_RATE) / 100
        );
    }

    function joinAsBoardMember(uint256 stake) external {
        require(stake >= minStake, "Stake must be at least minimum stake");
        require(!isMember[msg.sender], "Already a regular member");
        require(!isBoardMember[msg.sender], "Already a board member");
        isBoardMember[msg.sender] = true;
        totalAssetPool += stake;
        _transferTokens(msg.sender, address(this), stake);
        _transferTokens(msg.sender, taxAccount, (stake * TAX_RATE) / 100);
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

    // Internal function to handle transferring tokens
    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(token.transferFrom(from, to, amount), "Token transfer failed");
    }
}
