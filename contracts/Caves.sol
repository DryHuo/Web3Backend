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
        mapping(address => bool) votes;
    }

    struct Post {
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
        Proposal[] proposals;
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
        newDAO.treasryPool = initialStake;
        ownerToDAOIds[owner].push(daoCounter);
    }

    /**************************************************************************
     *                                Posts                                   *
     **************************************************************************/
    function createPost(
        address daoOwner,
        uint256 daoIndex,
        string memory content,
        string[] memory imageHashes,
        address author
    ) external {
        DAO storage dao = daos[daoIndex];
        Post memory newPost;
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
        address daoOwner,
        uint256 daoIndex,
        string memory description,
        address proposer
    ) external {
        DAO storage dao = daos[daoIndex];
        Proposal memory newProposal;
        newProposal.description = description;
        newProposal.proposer = proposer;
        dao.proposals.push(newProposal);
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
