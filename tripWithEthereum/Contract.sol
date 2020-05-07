pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Participant {
        address ethAddress;
        uint balance;
        bool deactivated;
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
        assert(deadlineDate > block.timestamp);
        assert(endingDate > deadlineDate);
        assert(trustMode > 0);
        assert(trustMode <= 3);
        assert(price > 0);
        assert(price <= 100000000000000000000);
        assert(maxPeople > 0);
        assert(maxPeople <= 30);
        
        Trip storage newTrip = trips[uuid];
        
        newTrip.participantNumber = 0;
        
        newTrip.participants[newTrip.participantNumber] = Participant( msg.sender, msg.value, false);
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
        assert(trips[uuid].deadlineDate > block.timestamp);
        
        bool isContained = false;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                isContained = true;
            }
        }
        
        if (!isContained) {
            trips[uuid].participants[trips[uuid].participantNumber] = Participant(msg.sender, msg.value , false);
            trips[uuid].participantNumber++;
        } else {
            revert();
        }
    }
    
    function unsubscribeFromTrip(string memory uuid) public {
        assert(trips[uuid].deadlineDate > block.timestamp);
        assert(compareStrings(trips[uuid].status,"ORGANIZING"));
        
        bool isContained = false;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                trips[uuid].participants[i].deactivated = true;
                isContained = true;
            }
            if (isContained) {
                trips[uuid].participants[i] = trips[uuid].participants[i+1];
            }
        }
        
        if (isContained) {
            msg.sender.transfer(trips[uuid].price);
            trips[uuid].participantNumber--;
        } else {
            revert();
        }

    }


    function getTripParticipant(string calldata uuid, uint partId) external view returns (address, uint, bool) {
        Participant memory toReturn = trips[uuid].participants[partId];
        return (toReturn.ethAddress,
                toReturn.balance,
                toReturn.deactivated
        );
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
