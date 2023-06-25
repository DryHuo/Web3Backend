// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PostContract {
    struct Post {
        string imageHash; // IPFS hash of the image
        string text; // description or details about the post
        address owner; // owner of the post
    }

    Post[] public posts;

    function addPost(string calldata imageHash, string calldata text) external {
        Post memory newPost = Post({
            imageHash: imageHash,
            text: text,
            owner: msg.sender
        });
        posts.push(newPost);
    }

    function getPost(
        uint256 postIndex
    ) external view returns (string memory, string memory, address) {
        Post memory post = posts[postIndex];
        return (post.imageHash, post.text, post.owner);
    }
}
