//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SocialMediaPlatform {

    event UserLoggedI(address user);
    event PostAdded(address user,string content);
    event UserJoinedGroup(address user,string groupName);
    event ContentModerated(address user, string content);

    struct ModerationItem {
        address user;
        string content;
    }

    mapping(address => string) private userPasswords;
    mapping(address => string) private userData;


    mapping(address => string[]) private userPosts;


    mapping(string => bool) private moderatedContent;
    ModerationItem[] private moderationQueue;
    bool public login = false;
    string[] private groupNames; 

    struct Group {
        string name;
        address[] members;
        string[] posts;
    }
    mapping(string => Group) private groups;

    function logout() external {
        login = false;
    }


    function createAccount(string calldata password, string calldata userData_) external {
        userPasswords[msg.sender] = password;
        userData[msg.sender] = userData_;
    }

    function authenticateUser(string calldata password) external returns (bool) {
        if (keccak256(abi.encodePacked(userPasswords[msg.sender])) == keccak256(abi.encodePacked(password))==true){
            login = true;
            emit UserLoggedI(msg.sender);
            return true;
        }
        else {
            return false;
        }
    }


    function postContent(string calldata content) external {
        require(login, "Please log in");
        emit PostAdded(msg.sender, content);
        userPosts[msg.sender].push(content);
    }

    function getUserPosts(address user) external view returns (string[] memory) {
        require(login, "Please log in");
        return userPosts[user];
    }

    function getContent(string calldata content) external view returns (string memory) {
        require(login, "Please log in");
        string[] memory posts = userPosts[msg.sender];
        for (uint i = 0; i < posts.length; i++) {
            if (keccak256(abi.encodePacked(posts[i])) == keccak256(abi.encodePacked(content))) {
                return userData[msg.sender];
            }
        }
        revert("Content not found");
    }


    function reportContent(string calldata content) external {
        require(login, "Please log in");
        moderationQueue.push(ModerationItem(msg.sender, content));
    }

    function moderateContent(string calldata content) external returns (bool) {
        require(login, "Please log in");
        for (uint i = 0; i < moderationQueue.length; i++) {
            if (keccak256(abi.encodePacked(moderationQueue[i].content)) == keccak256(abi.encodePacked(content))) {
                moderatedContent[content] = true;
                emit ContentModerated(moderationQueue[i].user, content);
                rewardUser(moderationQueue[i].user);
                delete moderationQueue[i];
                return true;
            }
        }
        return false;
    }

    function isModerated(string calldata content) external view returns (bool) {
        require(login, "Please log in");
        return moderatedContent[content];
    }


    function createGroup(string calldata name) external {
        require(login, "Please log in");
        groups[name] = Group(name, new address[](0), new string[](0)  );
        groupNames.push(name);
    }

    function joinGroup(string calldata name) external {
        require(login, "Please log in");
        emit UserJoinedGroup(msg.sender, name);
        groups[name].members.push(msg.sender);
    }

    function postInGroup(string calldata name, string calldata content) external {
        require(login, "Please log in");
        require(isUserInGroup(name, msg.sender), "join group"); 
        groups[name].posts.push(content);
    }

    function getGroupPosts(string calldata name) external view returns (string[] memory) {
        require(login, "Please log in");
        require(isUserInGroup(name, msg.sender), "join group"); 
        return groups[name].posts;
    }

    function getGroupUsers(string calldata name) external view returns (address[] memory){
        require(login, "Please log in");
        require(isUserInGroup(name, msg.sender), "join group"); 
        return groups[name].members;
    }

    mapping(address => mapping(string => bool)) private userContentVisibility;


    mapping(address => uint256) private userRewards;
    uint256 private constant REWARD_AMOUNT = 1000000000000; 


    mapping(address => mapping(string => bool)) private externalPlatformContent;

    function rewardUser(address user) internal {
        require(login, "Please log in");
        userRewards[user] += REWARD_AMOUNT;
    }

    function getUserReward(address user) external view returns (uint256) {
        require(login, "Please log in");
        
        return userRewards[user];
    }

    function isUserInGroup(string calldata name, address user) internal view returns (bool) {
        address[] memory members = groups[name].members;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == user) {
                return true;
            }
        }
        return false;
    }

    function importContent(address externalPlatform, string calldata content) external {
        require(login, "Please log in");
        externalPlatformContent[externalPlatform][content] = true;
    }

    function isExternalContent(address externalPlatform, string calldata content) external view returns (bool) {
        require(login, "Please log in");
        return externalPlatformContent[externalPlatform][content];
    }
    
    function getAllGroups() external view returns (string[] memory) {
        require(login, "Please log in");
        return groupNames; // Return all group names
    }
}
