pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract TripWithEthereum is Ownable {
    
    struct Participant {
        address payable ethAddress;
        uint balance;
    }
    
    struct Transaction {
        address payable to;
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
        bool ended;
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
        
        newTrip.transactions[newTrip.transactionNumber] = Transaction( msg.sender, 0, "FINISHED");
        newTrip.participants[newTrip.participantNumber] = Participant( msg.sender, msg.value);
        newTrip.participantNumber++;
        
        newTrip.organizer = msg.sender;
        
        newTrip.price = price;
        newTrip.tripBalance = msg.value;
        newTrip.maxPeople = maxPeople;
        newTrip.trustMode = trustMode;
        newTrip.deadlineDate = deadlineDate;
        newTrip.endingDate = endingDate;
        newTrip.ended = false;

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
            trips[uuid].participants[trips[uuid].participantNumber] = Participant(msg.sender, msg.value);
            trips[uuid].tripBalance += msg.value;
            trips[uuid].participantNumber++;
        } else {
            revert();
        }
    }
    
    function unsubscribeFromTrip(string memory uuid) public {
        assert(trips[uuid].deadlineDate > block.timestamp);
        assert(trips[uuid].organizer != msg.sender);
        
        bool isContained = false;
        uint index;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                index = i;
                isContained = true;
            }
            if (isContained) {
                trips[uuid].participants[i] = trips[uuid].participants[i+1];
            }
        }
        
        assert(trips[uuid].participants[index].balance >= 0);
        
        if (isContained) {
            uint toRefund = trips[uuid].participants[index].balance;
            trips[uuid].participants[index].balance = 0;
            trips[uuid].tripBalance -= toRefund;
            if (toRefund > 0) msg.sender.transfer(toRefund);
            trips[uuid].participantNumber--;
        } else {
            revert();
        }

    }
    
    function endTrip(string memory uuid) public {
        assert(trips[uuid].endingDate < block.timestamp);
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            uint toRefund = trips[uuid].participants[i].balance;
            trips[uuid].participants[i].balance = 0;
            trips[uuid].tripBalance -= toRefund;
            if (toRefund > 0) trips[uuid].participants[i].ethAddress.transfer(toRefund);
        }
        
        
        trips[uuid].ended = true;
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
                    trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] = true;
                } else {
                    trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] = false;
                }
            }
            
            if (trips[uuid].trustMode == 2) {
                checkVoteMajority(uuid);
            }
            
        }
        
    }
    
    function getVotePercent(string memory uuid) public view returns(uint){
        uint votePercentage;
        uint yesVotes = 0;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] == true) yesVotes += 1;
        }
        votePercentage = (yesVotes * 100) / (trips[uuid].participantNumber);
        
        return (votePercentage);
    }
    
    
    function checkVoteMajority(string memory uuid) public returns(bool){
        uint votePercentage;
        uint yesVotes = 0;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] == true) yesVotes += 1;
        }
        votePercentage = (yesVotes * 100) / (trips[uuid].participantNumber);
        
        if (votePercentage >= 50) {
            for (uint i=0; i<trips[uuid].participantNumber; i++) {
                trips[uuid].participants[i].balance -= trips[uuid].transactions[trips[uuid].transactionNumber].amount;
                trips[uuid].tripBalance -= trips[uuid].transactions[trips[uuid].transactionNumber].amount;
                
            }
            uint toTransfer = (trips[uuid].transactions[trips[uuid].transactionNumber].amount * trips[uuid].participantNumber);
            trips[uuid].transactions[trips[uuid].transactionNumber].to.transfer(toTransfer);
            trips[uuid].transactions[trips[uuid].transactionNumber].status = "FINISHED";
            return (true);
        }else {
            return (false);
        }
    }
    
    function checkVoteAll(string memory uuid) public returns(bool){
        bool everyVote = true;
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] != true) everyVote = false;
        }

        if (everyVote) {
            for (uint i=0; i<trips[uuid].participantNumber; i++) {
                trips[uuid].participants[i].balance -= trips[uuid].transactions[trips[uuid].transactionNumber].amount;
                trips[uuid].tripBalance -= trips[uuid].transactions[trips[uuid].transactionNumber].amount;
                
            }
            uint toTransfer = (trips[uuid].transactions[trips[uuid].transactionNumber].amount * trips[uuid].participantNumber);
            trips[uuid].transactions[trips[uuid].transactionNumber].to.transfer(toTransfer);
            trips[uuid].transactions[trips[uuid].transactionNumber].status = "FINISHED";
            return (true);
        }else {
            return (false);
        }
    }


    function makeVote(string memory uuid) public {
        assert(compareStrings(trips[uuid].transactions[trips[uuid].transactionNumber].status,"PENDING"));
        
        for (uint i=0; i<trips[uuid].participantNumber; i++) {
            if (trips[uuid].participants[i].ethAddress == msg.sender) {
                trips[uuid].transactions[trips[uuid].transactionNumber].votes[i] = true;
            }
        }
        
        if (trips[uuid].trustMode == 2) {
            checkVoteMajority(uuid);
        } else if (trips[uuid].trustMode == 1) {
            checkVoteAll(uuid);
        }
    }
    

    function getTripParticipant(string calldata uuid, uint partId) external view returns (address, uint) {
        Participant memory toReturn = trips[uuid].participants[partId];
        return (toReturn.ethAddress,
                toReturn.balance
        );
    }
    
    function getTripTransaction(string calldata uuid, uint transId) external view returns (address, uint, string memory) {
        Transaction memory toReturn = trips[uuid].transactions[transId];
        return (toReturn.to,
                toReturn.amount,
                toReturn.status
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

