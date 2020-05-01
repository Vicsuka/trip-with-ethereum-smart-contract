pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "../Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Participant {
        string name;
        address ethAddress;
        uint balance;
    }
    
    struct Trip {
        address  organizer;
        uint  price;
        uint  maxPeople;
        uint trustMode;
        mapping(uint => Participant) participants;
        uint participantNumber;
        string status;
    }
    
    mapping(string => Trip) public trips;
    string[] public tripIds;

    
    constructor() public {
    }

    
    function createTrip(string memory uuid, uint price, uint maxPeople, uint trustMode, string memory name) public payable {
        assert(price <= msg.value);
        
        Trip storage newTrip = trips[uuid];
        
        newTrip.participants[newTrip.participantNumber] = Participant(name, msg.sender, msg.value);
        newTrip.participantNumber++;
        
        newTrip.organizer = msg.sender;
        
        newTrip.price = price;
        newTrip.maxPeople = maxPeople;
        newTrip.trustMode = trustMode;
        newTrip.status = "ORGANIZING";

        tripIds.push(uuid);
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

}

