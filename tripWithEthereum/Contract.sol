pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Participant {
        address ethAddress;
        uint balance;
    }
    
    struct Trip {
        address  organizer;
        uint  price;
        uint  maxPeople;
        uint trustMode;
        uint participantNumber;
        string status;
        uint deadlineDate;
        uint endingDate;
        mapping(uint => Participant) participants;
    }
    
    mapping(string => Trip) public trips;
    string[] public tripIds;

    
    constructor() public {
    }

    
    function createTrip(string memory uuid, uint price, uint maxPeople, uint trustMode, uint deadlineDate, uint endingDate) public payable {
        assert(price <= msg.value);
        assert(deadlineDate > now);
        assert(endingDate > deadlineDate);
        assert(trustMode > 0);
        assert(trustMode <= 3);
        assert(price > 0);
        assert(price <= 100);
        assert(maxPeople > 0);
        assert(maxPeople <= 30);
        
        Trip storage newTrip = trips[uuid];
        
        newTrip.participantNumber = 0;
        
        newTrip.participants[newTrip.participantNumber] = Participant( msg.sender, msg.value);
        newTrip.participantNumber++;
        
        newTrip.organizer = msg.sender;
        
        newTrip.price = price;
        newTrip.maxPeople = maxPeople;
        newTrip.trustMode = trustMode;
        newTrip.status = "ORGANIZING";
        newTrip.deadlineDate = deadlineDate;
        newTrip.endingDate = endingDate;

        tripIds.push(uuid);
    }
    
    function applyToTrip(string memory uuid) public payable {
        assert(trips[uuid].price <= msg.value);
        assert(trips[uuid].maxPeople > trips[uuid].participantNumber);
        assert(compareStrings(trips[uuid].status,"ORGANIZING"));
        assert(trips[uuid].deadlineDate > now);
        
        trips[uuid].participants[trips[uuid].participantNumber] = Participant(msg.sender, msg.value);
    }

    
    function getTrip(string calldata uuid) external view returns (address, uint, uint, uint, string memory) {
        Trip memory toReturn = trips[uuid];
        return (toReturn.organizer,
                toReturn.price,
                toReturn.maxPeople,
                toReturn.trustMode,
                toReturn.status
        );
    }
    
    function compareStrings (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }

}

