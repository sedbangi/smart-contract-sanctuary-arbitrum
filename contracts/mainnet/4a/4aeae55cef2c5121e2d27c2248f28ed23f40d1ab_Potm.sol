// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Potm {
    struct Prize {
        string name;
        address winner;
        bool isClaimed;
    }

    Prize[] public prizes;
    mapping(address => uint256) public ticketsPerParticipant;
    mapping(address => uint256) public initialTicketsPerParticipant;

    address[] public participants;
    bool public hasDrawn = false;
    address public owner;
    uint256 public claimDeadline;
    uint256 constant CLAIM_DURATION = 7 days;

    event PrizeDrawn(string prizeName, address winner);
    event PrizeClaimed(string prizeName, address claimer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        prizes.push(Prize("Pudgy Penguin #196", address(0), false));
        prizes.push(Prize("Lil Pudgy #16565", address(0), false));
        prizes.push(Prize("Lil Pudgy #18590", address(0), false));
        prizes.push(Prize("Lil Pudgy #18584", address(0), false));
        prizes.push(Prize("Lil Pudgy #20259", address(0), false));
        prizes.push(Prize("10000 PINGU", address(0), false));
        prizes.push(Prize("9000 PINGU", address(0), false));
        prizes.push(Prize("8000 PINGU", address(0), false));
        prizes.push(Prize("7000 PINGU", address(0), false));
        prizes.push(Prize("6000 PINGU", address(0), false));
        prizes.push(Prize("5000 PINGU", address(0), false));
        prizes.push(Prize("4500 PINGU", address(0), false));
        prizes.push(Prize("4000 PINGU", address(0), false));
        prizes.push(Prize("3500 PINGU", address(0), false));
        prizes.push(Prize("3000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
        prizes.push(Prize("2000 PINGU", address(0), false));
    }

    function addParticipants(address[] memory _participants, uint256[] memory _tickets) public onlyOwner {
        require(_participants.length == _tickets.length, "Participants and tickets must match");
        for (uint i = 0; i < _participants.length; i++) {
            require(ticketsPerParticipant[_participants[i]] == 0, "Participant already added");
            ticketsPerParticipant[_participants[i]] = _tickets[i];
            initialTicketsPerParticipant[_participants[i]] = _tickets[i];
            participants.push(_participants[i]);
        }
    }

    function drawPrizes() public onlyOwner {
        require(!hasDrawn, "Draw has already been performed");
        hasDrawn = true;
        claimDeadline = block.timestamp + CLAIM_DURATION;

        for (uint i = 0; i < prizes.length; i++) {
            uint256 winnerIndex = getRandomWinner();
            prizes[i].winner = participants[winnerIndex];
            ticketsPerParticipant[participants[winnerIndex]] = 0;
            emit PrizeDrawn(prizes[i].name, participants[winnerIndex]);
        }
    }

    function claimPrize(uint256 prizeIndex) public {
        require(prizes[prizeIndex].winner == msg.sender, "You are not the winner of this prize");
        require(block.timestamp <= claimDeadline, "Claim period has ended");
        prizes[prizeIndex].isClaimed = true;
        emit PrizeClaimed(prizes[prizeIndex].name, msg.sender);
    }

    function wonPrize(address _address) public view returns (string memory) {
        for (uint i = 0; i < prizes.length; i++) {
            if (prizes[i].winner == _address) {
                return prizes[i].name;
            }
        }
        return "No prize won";
    }

    function wonPrizeIndex(address _address) public view returns (int) {
        for (uint i = 0; i < prizes.length; i++) {
            if (prizes[i].winner == _address) {
                return int(i);
            }
        }
        return -1;
    }

    function hasClaimed(address _address) public view returns (bool) {
        for (uint i = 0; i < prizes.length; i++) {
            if (prizes[i].winner == _address && prizes[i].isClaimed) {
                return true;
            }
        }
        return false;
    }

    function getWinnersAndPrizes() public view returns (address[] memory, string[] memory) {
        address[] memory winners = new address[](prizes.length);
        string[] memory prizeNames = new string[](prizes.length);
        for (uint i = 0; i < prizes.length; i++) {
            winners[i] = prizes[i].winner;
            prizeNames[i] = prizes[i].name;
        }
        return (winners, prizeNames);
    }

    function getTicketCount(address _participant) public view returns (uint256) {
        return initialTicketsPerParticipant[_participant];
    }

    function getClaimDeadline() public view returns (uint256) {
        return claimDeadline;
    }

    function getRandomWinner() private view returns (uint256) {
        uint256 totalTickets = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            totalTickets += ticketsPerParticipant[participants[i]];
        }

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % totalTickets;
        uint256 sum = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            sum += ticketsPerParticipant[participants[i]];
            if (random < sum) {
                return i;
            }
        }
        return 0;
    }
}