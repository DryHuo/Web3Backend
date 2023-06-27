// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Caves {
    IERC20 public token;
    address private _taxAccount; // The address that receives the tax fees
    uint256 public constant TAX_RATE = 2; // The tax rate is 2%
    uint256 public constant MIN_INIT_STAKE = 10; // The minimum amount of tokens to stake to create a DAO

    enum ProposalType {
        PublishPost,
        LeaveDAO
    }

    struct Proposal {
        ProposalType proposalType;
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
        string title;
        string content;
        address author;
        uint256 timestamp;
        bool isPublished;
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
        bool isValue; // Used to check if the DAO exists
    }

    mapping(string => DAO) public daos; // DAOs by names
    mapping(bytes32 => Post) private posts; // Posts by hashes
    mapping(bytes32 => Proposal) private proposals; // Proposals by hashes

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
            !daos[name].isValue,
            "There is already a DAO with this name. Please choose another name"
        );
        require(
            initialStake >= MIN_INIT_STAKE,
            "Initial stake is less than minimum stake required"
        );
        DAO storage newDAO = daos[name];
        newDAO.name = name;
        newDAO.initiator = msg.sender;
        newDAO.minStake = minStake;
        newDAO.description = description;
        newDAO.isValue = true;

        uint256 tax = (initialStake * TAX_RATE) / 100;
        token.transferFrom(msg.sender, _taxAccount, tax);
        token.transferFrom(msg.sender, address(this), initialStake - tax);

        newDAO.treasryPool = initialStake - tax;

        emit DAOCreated(name, msg.sender);
    }

    function joinAsBoardMember(string memory daoName, uint256 stake) external {
        require(
            daos[daoName].isValue,
            "There is no DAO with this name. Please check the name and try again"
        );
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

        emit BoardMemberJoined(daoName, stake, tax, msg.sender);
    }

    function joinAsMember(string memory daoName) external {
        DAO storage dao = daos[daoName];
        dao.members.push(msg.sender);

        emit MemberJoined(daoName, msg.sender);
    }

    /**************************************************************************
     *                                Posts                                   *
     **************************************************************************/
    function createPost(
        string memory daoName,
        string memory title,
        string memory content,
        string[] memory imageHashes,
        address author
    ) external {
        DAO storage dao = daos[daoName];
        Post memory newPost;
        newPost.dao = daoName;
        newPost.title = title;
        newPost.content = content;
        newPost.imageHashes = imageHashes;
        newPost.author = author;
        newPost.timestamp = block.timestamp;
        dao.posts.push(newPost);

        emit PostCreated(daoName, title, author);
    }

    /**************************************************************************
     *                              Proposals                                 *
     **************************************************************************/
    function createProposal(
        string memory daoName,
        string memory description,
        string memory proposalType,
        address proposer
    ) external {
        DAO storage dao = daos[daoName];
        dao.pendingProposals.push();

        Proposal storage newProposal = dao.pendingProposals[
            dao.pendingProposals.length - 1
        ];
        newProposal.proposalType = _string2ProposalType(proposalType);
        newProposal.proposer = proposer;

        bytes32 proposalID = keccak256(
            abi.encodePacked(daoName, description, proposalType, proposer)
        );
        proposals[proposalID] = newProposal;
        emit ProposalCreated(daoName, proposalID, proposer);
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

        if (proposal.voters.length == dao.board.length) {
            uint256 yesVotes = 0;
            uint256 noVotes = 0;
            for (uint256 i = 0; i < proposal.votes.length; i++) {
                if (proposal.votes[i]) {
                    yesVotes++;
                } else {
                    noVotes++;
                }
            }
            if (yesVotes > noVotes) {
                proposal.isAccepted = true;
                dao.acceptedProposals.push(proposal);
            }
        }
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

    function _string2ProposalType(
        string memory proposalType
    ) internal pure returns (ProposalType) {
        if (keccak256(bytes(proposalType)) == keccak256(bytes("PublishPost"))) {
            return ProposalType.PublishPost;
        } else if (
            keccak256(bytes(proposalType)) == keccak256(bytes("LeaveDAO"))
        ) {
            return ProposalType.LeaveDAO;
        } else {
            revert("Invalid proposal type");
        }
    }

    /**************************************************************************
     *                               Events                                   *
     **************************************************************************/
    event DAOCreated(string indexed name, address indexed initiator);
    event BoardMemberJoined(
        string indexed daoName,
        uint256 stake,
        uint256 tax,
        address indexed member
    );
    event MemberJoined(string indexed daoName, address indexed member);
    event PostCreated(
        string indexed daoName,
        string title,
        address indexed author
    );
    event ProposalCreated(
        string indexed daoName,
        bytes32 indexed proposalHash,
        address indexed proposer
    );
    event ProposalVoted(
        string indexed daoName,
        bytes32 indexed proposalHash,
        bool vote,
        address indexed voter
    );
}
