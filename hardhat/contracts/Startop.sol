// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

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

    // Define a structure for a Comment.
    struct Comment {
        uint id;
        uint pitchId;
        address commenter;
        string text;
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
        uint dislikes;
        string tags;
        Comment[] comments;
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
    event PitchUploaded(uint id, string hash, string description, uint tipAmount, address author, uint timestamp, uint likes, uint dislikes, string tags);

    // Event to log when a pitch is tipped.
    event PitchTipped(uint id, string hash, string description, uint tipAmount, address author);

    // Event to log when a user is registered.
    event UserRegistered(address userAddress, string username);

    // Event to log when a pitch is liked.
    event Liked(uint id);

    // Event to log when a pitch is disliked.
    event Disliked(uint id);

    // Event to log when a user joins a team.
    event JoinedTeam(uint teamId, address user);

    // Event to log when a bid is placed.
    event BidPlaced(uint id, uint pitchId, address bidder, string comments);

    // Event to log when a pitch is commented.
    event Commented(uint pitchId, uint commentId, address commenter, string text);

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
        pitches[pitchCount] = Pitch(pitchCount, _videoHash, _description, 0, msg.sender, timestamp, 0, 0, _tags, new Comment[](0), new uint[](0), new uint[](0));
        // Create a new pitch and add it to the pitches mapping.
        users[msg.sender].contributedPitches.push(pitchCount); // Add the pitch to the user's contributed pitches.
        emit PitchUploaded(pitchCount, _videoHash, _description, 0, msg.sender, timestamp, 0, 0, _tags);
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
            body: 'User tipped your pitch with the ID ' + uintToString(_id) + '.'
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
    function likePitch(uint _id) public {
        require(_id > 0 && _id <= pitchCount); // Ensure a valid pitch ID.
        Pitch storage _pitch = pitches[_id]; // Get the pitch by ID.
        _pitch.likes++; // Increment the likes for the pitch.
        pitches[_id] = _pitch; // Update the pitch in the mapping.
        emit Liked(_id); // Emit an event to log the pitch like.

        // Send a push notification to the user.
        NotificationPayload memory notificationPayload = NotificationPayload({
            title: 'Your pitch was liked!',
            body: 'Liked the pitch ' + uintToString(_id) + '.'
        });
        sendNotification(_pitch.author, notificationPayload);
    }

    // Function to dislike a pitch.
    function dislikePitch(uint _id) public {
        require(_id > 0 && _id <= pitchCount); // Ensure a valid pitch ID.
        Pitch storage _pitch = pitches[_id]; // Get the pitch by ID.
        _pitch.dislikes++; // Increment the dislikes for the pitch.
        pitches[_id] = _pitch; // Update the pitch in the mapping.
        emit Disliked(_id); // Emit an event to log the pitch dislike.

        // Send a push notification to the user (optional).
        NotificationPayload memory notificationPayload = NotificationPayload({
            title: 'Your pitch was disliked!',
            body: 'Disliked the pitch ' + uintToString(_id) + '.'
        });
        sendNotification(_pitch.author, notificationPayload);
    }

    // Function to comment on a pitch.
    function commentPitch(uint _pitchId, string memory _text) public {
        require(_pitchId > 0 && _pitchId <= pitchCount); // Ensure a valid pitch ID.
        require(bytes(_text).length > 0); // Ensure a valid comment text.

        uint commentId = pitches[_pitchId].comments.length + 1;
        pitches[_pitchId].comments.push(Comment(commentId, _pitchId, msg.sender, _text));
        emit Commented(_pitchId, commentId, msg.sender, _text);
    }

    // ... (other functions for creating teams, joining teams, placing bids, etc.)

    // Helper function to convert uint to string (you can implement this).
    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // Trim unused characters
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        return string(s);
    }
}
