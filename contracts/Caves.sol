// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Caves {
    IERC20 public token;
    address private _taxAccount; // The address that receives the tax fees
    uint256 public constant TAX_RATE = 2; // The tax rate is 2%
    uint256 public constant MIN_INIT_STAKE = 10; // The minimum amount of tokens to stake to create a DAO

    struct Proposal {
        string description;
        address proposer;
        bool isAccepted;
        uint256 voteCounter;
        address[] voters;
        bool[] votes;
    }

    struct Post {
        string dao; // The DAO that the post belongs to
        string[] imageHashes; // change to NFT addresses after implementing NFTs
        string[] imageAddresses;
        string content;
        address author;
        uint256 timestamp;
    }

    struct DAO {
        string name;
        string description;
        address initiator; // The address that created the DAO
        uint256 minStake; // Minimum amount of tokens to stake to become a board member
        uint256 treasryPool; // Total amount of tokens staked in the DAO
        address[] board;
        address[] members;
        Proposal[] pendingProposals;
        Proposal[] acceptedProposals;
        Post[] posts;
    }

    mapping(string => DAO) public daos; // DAOs by names

    constructor(address tokenAddress, address taxAccount) {
        token = IERC20(tokenAddress);
        _taxAccount = taxAccount;
    }

    /**************************************************************************
     *                          DAO Functionality                             *
     **************************************************************************/
    function createDAO(
        string memory name,
        string memory description,
        uint256 minStake,
        uint256 initialStake
    ) external {
        require(
            initialStake >= MIN_INIT_STAKE,
            "Initial stake is less than minimum stake required"
        );
        DAO storage newDAO = daos[name];
        newDAO.name = name;
        newDAO.initiator = msg.sender;
        newDAO.minStake = minStake;
        newDAO.description = description;

        uint256 tax = (initialStake * TAX_RATE) / 100;
        token.transferFrom(msg.sender, _taxAccount, tax);
        token.transferFrom(msg.sender, address(this), initialStake - tax);

        newDAO.treasryPool = initialStake - tax;
    }

    function joinAsBoardMember(string memory daoName, uint256 stake) external {
        DAO storage dao = daos[daoName];
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

    function joinAsMember(string memory daoName) external {
        DAO storage dao = daos[daoName];
        dao.members.push(msg.sender);
    }

    /**************************************************************************
     *                                Posts                                   *
     **************************************************************************/
    function createPost(
        string memory daoName,
        string memory content,
        string[] memory imageHashes,
        address author
    ) external {
        DAO storage dao = daos[daoName];
        Post memory newPost;
        newPost.dao = daoName;
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
        string memory daoName,
        string memory description,
        address proposer
    ) external {
        DAO storage dao = daos[daoName];
        dao.pendingProposals.push();

        Proposal storage newProposal = dao.pendingProposals[
            dao.pendingProposals.length - 1
        ];
        newProposal.description = description;
        newProposal.proposer = proposer;
    }

    function voteProposal(
        string memory daoName,
        uint256 proposalIndex,
        bool vote
    ) external {
        DAO storage dao = daos[daoName];
        Proposal storage proposal = dao.pendingProposals[proposalIndex];
        require(
            _isInArray(dao.board, msg.sender),
            "You are not a member of this DAO"
        );
        require(
            !_isInArray(proposal.voters, msg.sender),
            "You have already voted on this proposal"
        );
        proposal.voters.push(msg.sender);
        proposal.votes.push(vote);
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

    function _isInArray(
        address[] memory array,
        address element
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }
}
