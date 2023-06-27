// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Caves {
    IERC20 public token;
    address private _taxAccount; // The address that receives the tax fees
    uint256 public constant TAX_RATE = 2; // The fee rate is 2%
    uint256 public constant MIN_INIT_STAKE = 10; // The minimum amount of tokens to stake to create a DAO

    struct Proposal {
        string description;
        address proposer;
        bool isAccepted;
        uint256 totalVotes;
        address[] voters;
        uint8[] votes; // 0 = no vote, 1 = yes, 2 = no
    }

    struct Post {
        DAO dao; // The DAO that the post belongs to
        string[] imageHashes; // change to NFT addresses after implementing NFTs
        string[] imageAddresses;
        string content;
        address author;
        uint256 timestamp;
    }

    struct DAO {
        address owner; // The address that created the DAO
        uint256 minStake; // Minimum amount of tokens to stake to become a board member
        uint256 treasryPool; // Total amount of tokens staked in the DAO
        address[] board;
        address[] members;
        Proposal[] pendingProposals;
        Proposal[] acceptedProposals;
        Post[] posts;
    }

    mapping(uint256 => DAO) public daos; // DAOs by ID
    mapping(address => uint256[]) public ownerToDAOIds; // All DAOs owned by an address
    uint256 public daoCounter; // Counter to generate unique DAO IDs

    constructor(address tokenAddress, address taxAccount) {
        token = IERC20(tokenAddress);
        _taxAccount = taxAccount;
    }

    /**************************************************************************
     *                          DAO Functionality                             *
     **************************************************************************/
    function createDAO(
        address owner,
        uint256 minStake,
        uint256 initialStake
    ) external {
        require(
            initialStake >= MIN_INIT_STAKE,
            "Initial stake is less than minimum stake required"
        );
        daoCounter++;
        DAO storage newDAO = daos[daoCounter];
        newDAO.owner = owner;
        newDAO.minStake = minStake;

        uint256 tax = (initialStake * TAX_RATE) / 100;
        token.transferFrom(owner, _taxAccount, tax);
        token.transferFrom(owner, address(this), initialStake - tax);

        newDAO.treasryPool = initialStake - tax;
        ownerToDAOIds[owner].push(daoCounter);
    }

    function joinAsBoardMember(uint256 daoIndex, uint256 stake) external {
        DAO storage dao = daos[daoIndex];
        require(
            token.balanceOf(msg.sender) >= dao.minStake,
            "You do not have enough tokens to join this DAO"
        );
        dao.board.push(msg.sender);
        dao.members.push(msg.sender);

        uint256 tax = (stake * TAX_RATE) / 100;
        token.transferFrom(msg.sender, _taxAccount, tax);
        token.transferFrom(msg.sender, address(this), stake - tax);

        dao.treasryPool += stake - tax;
    }

    function joinAsMember(uint256 daoIndex) external {
        DAO storage dao = daos[daoIndex];
        dao.members.push(msg.sender);
    }

    /**************************************************************************
     *                                Posts                                   *
     **************************************************************************/
    function createPost(
        uint256 daoIndex,
        string memory content,
        string[] memory imageHashes,
        address author
    ) external {
        DAO storage dao = daos[daoIndex];
        Post memory newPost;
        newPost.dao = dao;
        newPost.content = content;
        newPost.imageHashes = imageHashes;
        newPost.author = author;
        newPost.timestamp = block.timestamp;
        dao.posts.push(newPost);
    }

    /**************************************************************************
     *                              Proposals                                 *
     **************************************************************************/
    function createProposal(
        uint256 daoIndex,
        string memory description,
        address proposer
    ) external {
        DAO storage dao = daos[daoIndex];
        Proposal memory newProposal;
        newProposal.description = description;
        newProposal.proposer = proposer;
        newProposal.voters = dao.board;
        newProposal.votes = new uint8[](dao.board.length);
        dao.pendingProposals.push(newProposal);
    }

    function voteProposal(
        uint256 daoIndex,
        uint256 proposalIndex,
        bool vote
    ) external {
        DAO storage dao = daos[daoIndex];
        Proposal storage proposal = dao.pendingProposals[proposalIndex];
        require(
            proposal.votes[dao.board.length - 1] == 0,
            "Proposal has already been voted on"
        );
        uint256 voteWeight = token.balanceOf(dao.board[proposal.voters.length]);
        if (vote) {
            proposal.votes[proposal.voters.length] = 1;
            proposal.totalVotes += voteWeight;
        } else {
            proposal.votes[proposal.voters.length] = 2;
        }
        proposal.voters.push(msg.sender);
    }

    /**************************************************************************
     *                           Private Functions                            *
     **************************************************************************/
    // Internal function to handle transferring tokens
    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(token.transferFrom(from, to, amount), "Token transfer failed");
    }
}
