// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import { PushAPI } from '@pushprotocol/restapi'; // Import the PushAPI from PushProtocol and ethers for Ethereum integration.

contract Startup {
    string public name; // Public variable to store the contract name.
    uint public pitchCount = 0; // Counter for the number of pitches created.
    uint public userCount = 0; // Counter for the number of users registered.
    uint public teamCount = 0; // Counter for the number of teams created.
    uint public bidCount = 0; // Counter for the number of bids placed.

    struct NotificationPayload {
        string title;
        string body;
    }

    // Define a structure for a pitch.
    struct Pitch {
        uint id;
        string hash; // IPFS hash for the video content.
        string description;
        uint tipAmount;
        address payable author;
        uint timestamp;
        uint likes;
        string tags;
        uint[] teamMembers;
        uint[] bids;
    }

    // Define a structure for a user.
    struct User {
        address userAddress;
        string username;
        uint[] contributedPitches;
    }

    // Define a structure for a team.
    struct Team {
        uint id;
        string name;
        address[] members;
    }

    // Define a structure for a bid.
    struct Bid {
        uint id;
        uint pitchId;
        address bidder;
        string comments;
    }

    // Create mappings to store pitches, users, teams, and bids.
    mapping(uint => Pitch) public pitches;
    mapping(address => User) public users;
    mapping(uint => Team) public teams;
    mapping(uint => Bid) public bids;

    // Event to log when a pitch is uploaded.
    event PitchUploaded(uint id, string hash, string description, uint tipAmount, address author, uint timestamp, uint likes, string tags);

    // Event to log when a pitch is tipped.
    event PitchTipped(uint id, string hash, string description, uint tipAmount, address author);

    // Event to log when a user is registered.
    event UserRegistered(address userAddress, string username);

    // Event to log when a pitch is liked.
    event Liked(uint id);

    // Event to log when a user joins a team.
    event JoinedTeam(uint teamId, address user);

    // Event to log when a bid is placed.
    event BidPlaced(uint id, uint pitchId, address bidder, string comments);

    // Contract constructor to initialize the contract name.
    constructor() {
        name = "Startop";
    }

    // Function to upload a pitch.
    function uploadPitch(string memory _videoHash, string memory _description, string memory _tags) public {
        require(bytes(_videoHash).length > 0); // Ensure the video hash is provided.
        require(bytes(_description).length > 0); // Ensure the pitch description is provided.
        require(msg.sender != address(0)); // Ensure a valid sender address.

        pitchCount++; // Increment the pitch count.
        uint timestamp = block.timestamp; // Get the current timestamp.
        pitches[pitchCount] = Pitch(pitchCount, _videoHash, _description, 0, msg.sender, timestamp, 0, _tags, new uint[](0), new uint[](0));
        // Create a new pitch and add it to the pitches mapping.
        users[msg.sender].contributedPitches.push(pitchCount); // Add the pitch to the user's contributed pitches.
        emit PitchUploaded(pitchCount, _videoHash, _description, 0, msg.sender, timestamp, 0, _tags);
        // Emit an event to log the pitch upload.
    }

    // Function to tip the owner of a pitch.
    function tipPitchOwner(uint _id) public payable {
        require(_id > 0 && _id <= pitchCount); // Ensure a valid pitch ID.
        Pitch storage _pitch = pitches[_id]; // Get the pitch by ID.
        address payable _author = _pitch.author; // Get the author's address.
        _author.transfer(msg.value); // Transfer the tip amount to the author.
        _pitch.tipAmount += msg.value; // Update the tip amount for the pitch.
        pitches[_id] = _pitch; // Update the pitch in the mapping.
        emit PitchTipped(_id, _pitch.hash, _pitch.description, _pitch.tipAmount, _author);
        // Emit an event to log the pitch tip.
        NotificationPayload memory notificationPayload = NotificationPayload({
            title: 'Your pitch was tipped!',
            body: 'User tipped your pitch with the ID ' + uintToString(id) + '.'
        });
        sendNotification(_pitch.author, notificationPayload);
        // Send a push notification to the author.
    }

    // Function to register a user.
    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0); // Ensure a valid username is provided.
        require(users[msg.sender].userAddress == address(0)); // Check if the user is not already registered.

        userCount++; // Increment the user count.
        users[msg.sender] = User(msg.sender, _username, new uint[](0)); // Create a new user and add it to the users mapping.
        emit UserRegistered(msg.sender, _username); // Emit an event to log the user registration.
    }

    // Function to like a pitch.
    function likePitch(uint id) public {
        require(_id > 0 && _id <= pitchCount); // Ensure a valid pitch ID.
        Pitch storage _pitch = pitches[_id]; // Get the pitch by ID.
        _pitch.likes++; // Increment the likes for the pitch.
        pitches[_id] = _pitch; // Update the pitch in the mapping.
        emit Liked(_id); // Emit an event to log the pitch like.

        // Send a push notification to the user.
        NotificationPayload memory notificationPayload = NotificationPayload({
            title: 'Your pitch was liked!',
            body: 'Liked the pitch ' + uintToString(id) + '.'
        });
        sendNotification(_pitch.author, notificationPayload);
    }

    // Function to create a team.
    function createTeam(string memory _teamName) public {
        require(bytes(_teamName).length > 0); // Ensure a valid team name is provided.
        teamCount++; // Increment the team count.
        teams[teamCount] = Team(teamCount, _teamName, new address[](0)); // Create a new team and add it to the teams mapping.
    }

    // Function to join a team.
    function joinTeam(uint _teamId) public {
        require(_teamId > 0 && _teamId <= teamCount); // Ensure a valid team ID.
        Team storage _team = teams[_teamId]; // Get the team by ID.
        _team.members.push(msg.sender); // Add the sender to the team's members.
        teams[_teamId] = _team; // Update the team in the mapping.
        emit JoinedTeam(_teamId, msg.sender); // Emit an event to log the user joining the team.
    }

    // Function to place a bid on a pitch.
    function placeBid(uint _pitchId, string memory _comments) public {
        require(_pitchId > 0 && _pitchId <= pitchCount); // Ensure a valid pitch ID.
        require(bytes(_comments).length > 0); // Ensure valid bid comments.
        bidCount++; // Increment the bid count.
        bids[bidCount] = Bid(bidCount, _pitchId, msg.sender, _comments); // Create a new bid and add it to the bids mapping.
        pitches[_pitchId].bids.push(bidCount); // Add the bid to the pitch's bids.
        emit BidPlaced(bidCount, _pitchId, msg.sender, _comments); // Emit an event to log the bid placement.

        NotificationPayload memory notificationPayload = NotificationPayload({
            title: 'Your pitch was bid!',
            body: 'User bid your pitch with the ID ' + uintToString(id) + '.'
        });
        sendNotification(_pitch.author, notificationPayload);
        // Send a push notification to the author of the pitch.
    }

    // Function to get the contributed pitches by a user.
    function getContributedPitches(address _user) public view returns (uint[] memory) {
        return users[_user].contributedPitches;
    }
}
