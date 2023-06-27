// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Caves {
    IERC20 public token;
    address private _taxAccount; // The address that receives the tax fees
    uint256 public constant TAX_RATE = 2; // The tax rate is 2%
    uint256 public constant MIN_INIT_STAKE = 10; // The minimum amount of tokens to stake to create a DAO
    uint256 public constant MAX_BOARD_MEMBERS = 5; // The maximum amount of board members in a DAO
    uint256 public constant MAX_MEMBERS = 20; // The maximum amount of members in a DAO

    struct Proposal {
        string description;
        address proposer;
        bool isAccepted;
        uint256 voteCounter;
        address[] voters;
        bool[] votes;
    }

    struct Post {
        uint256 daoID; // The DAO that the post belongs to
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
        uint256 maxBoardCount;
        address[] members;
        uint256 maxMemberCount;
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
        string memory name,
        string memory description,
        uint256 minStake,
        uint256 initialStake,
        uint256 maxBoardCount,
        uint256 maxMemberCount
    ) external {
        require(
            initialStake >= MIN_INIT_STAKE,
            "Initial stake is less than minimum stake required"
        );
        daoCounter++;
        DAO storage newDAO = daos[daoCounter];
        newDAO.name = name;
        newDAO.initiator = msg.sender;
        newDAO.minStake = minStake;
        newDAO.maxBoardCount = maxBoardCount;
        newDAO.maxMemberCount = maxMemberCount;
        newDAO.description = description;

        uint256 tax = (initialStake * TAX_RATE) / 100;
        token.transferFrom(msg.sender, _taxAccount, tax);
        token.transferFrom(msg.sender, address(this), initialStake - tax);

        newDAO.treasryPool = initialStake - tax;
        ownerToDAOIds[msg.sender].push(daoCounter);
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
        newPost.daoID = daoIndex;
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
        dao.pendingProposals.push();

        Proposal storage newProposal = dao.pendingProposals[
            dao.pendingProposals.length - 1
        ];
        newProposal.description = description;
        newProposal.proposer = proposer;
        newProposal.voters = new address[](dao.maxBoardCount);
        newProposal.votes = new bool[](dao.maxBoardCount);
    }

    function voteProposal(
        uint256 daoIndex,
        uint256 proposalIndex,
        bool vote
    ) external {
        DAO storage dao = daos[daoIndex];
        Proposal storage proposal = dao.pendingProposals[proposalIndex];
        require(
            _isInArray(dao.board, msg.sender),
            "You are not a member of this DAO"
        );
        require(
            !_isInArray(proposal.voters, msg.sender),
            "You have already voted on this proposal"
        );
        proposal.voteCounter++;
        proposal.voters[proposal.voteCounter] = msg.sender;
        proposal.votes[proposal.voteCounter] = vote;
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
