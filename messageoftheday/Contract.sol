pragma solidity ^0.6.0;

import "../Ownable.sol";

contract MessageOfTheMoment is Ownable {
    string public message;
    uint public maxLength;

    constructor() public {
        message = "Hello World";
        maxLength = 280;
    }

    function setMessage(string memory _message) public {
        require(bytes(_message).length <= maxLength, "That message is too long.");
        
        message = _message;
    }

    function setMaxLength(uint _maxLength) public onlyOwner {
        maxLength = _maxLength;
    }

}
