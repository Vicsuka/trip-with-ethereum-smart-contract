pragma solidity ^0.6.0;

import "../Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Trip {
      address  organizer;
      uint  price;
      uint  maxPeople;
      address[]  participants;
      string status;
    }
    
    mapping(string => Trip) public trips;

    
    constructor() public {
    }

    function createTrip(string memory uuid, address organizer, uint price, uint maxPeople) public {
        Trip memory newTrip;
        
        newTrip.organizer = organizer;
        newTrip.price = price;
        newTrip.maxPeople = maxPeople;
        newTrip.status = "ORGANIZING";
        
        //= Trip(organizer,price,maxPeople,[],Status.ORGANIZING);
        
        trips[uuid] = newTrip;
    }

    
    function getTrip(string calldata uuid) external view returns (address ,uint,uint, address[] memory,string memory) {
        Trip memory toReturn = trips[uuid];
        return (toReturn.organizer,
                toReturn.price,
                toReturn.maxPeople,
                toReturn.participants,
                toReturn.status
        );
    }

}
