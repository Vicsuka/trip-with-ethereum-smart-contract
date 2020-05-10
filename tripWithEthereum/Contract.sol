pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Participant {
        address ethAddress;
        uint balance;
        bool deactivated;
    }
    
    struct Transaction {
        address to;
        uint amount;
        string status;
        mapping(uint => bool) votes;
    }
    
    struct Trip {
        address  organizer;
        uint tripBalance;
        uint  price;
        uint  maxPeople;
        uint trustMode;
        uint participantNumber;
        uint deadlineDate;
        uint endingDate;
        uint transactionNumber;
        mapping(uint => Participant) participants;
        mapping(uint => Transaction) transactions;
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
        newTrip.transactionNumber = 0;
        
        newTrip.participants[newTrip.participantNumber] = Participant( msg.sender, msg.value, false);
        newTrip.participantNumber++;
        
        newTrip.organizer = msg.sender;
        
        newTrip.price = price;
        newTrip.tripBalance = msg.value;
        newTrip.maxPeople = maxPeople;
        newTrip.trustMode = trustMode;
        newTrip.deadlineDate = deadlineDate;
        newTrip.endingDate = endingDate;

        tripIds.push(uuid);
    }
    
    function applyToTrip(string memory uuid) public payable {
        assert(trips[uuid].price <= msg.value);
        assert(trips[uuid].maxPeople > trips[uuid].participantNumber);
        assert(trips[uuid].deadlineDate > block.timestamp);
        
        bool isContained = false;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                isContained = true;
            }
        }
        
        if (!isContained) {
            trips[uuid].participants[trips[uuid].participantNumber] = Participant(msg.sender, msg.value , false);
            trips[uuid].tripBalance += msg.value;
            trips[uuid].participantNumber++;
        } else {
            revert();
        }
    }
    
    function unsubscribeFromTrip(string memory uuid) public {
        assert(trips[uuid].deadlineDate > block.timestamp);
        
        bool isContained = false;
        uint index;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                index = i;
                trips[uuid].participants[i].deactivated = true;
                isContained = true;
            }
            if (isContained) {
                trips[uuid].participants[i] = trips[uuid].participants[i+1];
            }
        }
        
        assert(trips[uuid].participants[index].balance > 0);
        
        if (isContained) {
            uint toRefund = trips[uuid].participants[index].balance;
            trips[uuid].participants[index].balance = 0;
            trips[uuid].tripBalance -= toRefund;
            msg.sender.transfer(toRefund);
            trips[uuid].participantNumber--;
        } else {
            revert();
        }

    }
    
    function newTransaction(string memory uuid, address payable to, uint amount) public {
        assert(trips[uuid].organizer == msg.sender);
        assert(trips[uuid].tripBalance >= amount * trips[uuid].participantNumber);
        assert(compareStrings(trips[uuid].transactions[trips[uuid].transactionNumber].status,"FINISHED"));
        
        trips[uuid].transactionNumber++;
        
        trips[uuid].transactions[trips[uuid].transactionNumber] = Transaction(to,amount,"PENDING");
        
        if (trips[uuid].trustMode == 3) {
            for (uint i=0; i<trips[uuid].participantNumber; i++) {
                trips[uuid].participants[i].balance -= amount;
                trips[uuid].tripBalance -= amount;
                
            }
            uint toTransfer = (amount * trips[uuid].participantNumber);
            to.transfer(toTransfer);
            trips[uuid].transactions[trips[uuid].transactionNumber].status = "FINISHED";
            
        } else {
            for (uint i=0; i<trips[uuid].participantNumber; i++) {
                if (trips[uuid].participants[i].ethAddress == msg.sender) {
                    trips[uuid].participants[i].balance -= amount;
                    trips[uuid].tripBalance -= amount;
                    trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] = true;
                } else {
                    trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] = false;
                }
            }
            
        }
        
    }


    function makeVote() {
        
    }

    function getTripParticipant(string calldata uuid, uint partId) external view returns (address, uint, bool) {
        Participant memory toReturn = trips[uuid].participants[partId];
        return (toReturn.ethAddress,
                toReturn.balance,
                toReturn.deactivated
        );
    }
    
    function getTrip(string calldata uuid) external view returns (address, uint, uint, uint) {
        Trip memory toReturn = trips[uuid];
        return (toReturn.organizer,
                toReturn.price,
                toReturn.maxPeople,
                toReturn.trustMode
        );
    }
    
    function compareStrings (string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );
    }

}

