//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "./IToken.sol";

contract LotteryContract {

    struct Ticket{
        uint256 number;
        address owner;
    }

    struct Lottery{
        address owner;
        uint commissionPercent;

        uint256 startDate;
        uint256 endDate;

        uint256 ticketPrice;
        Ticket[] tickets;

        bool isWinnerChosen;
        Ticket winnerTicket;
    }

    Lottery[] public lotteries;
    event LotteryCreated(uint256 lotteryNumber, address lotteryOwner);
    event LotteryFinished(uint256 lotteryNumber, address winner, uint256 prizePool);
    event TicketsSold(uint256 lotteryNumber, address buyer, uint256 ticketsAmount);

    IToken private token;
    address private owner;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IToken(_tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier lotteryExists(uint256 _lotteryNumber) {
        checkIsLotteryExists(_lotteryNumber);
        _;
    }

    // TODO: Насколько это рандомно вообще
    function GetRandomTicket(Ticket[] memory tickets) private view returns (Ticket memory) {
        uint256 index = uint256(keccak256(abi.encodePacked(
            block.timestamp, block.difficulty, msg.sender, tickets.length))) % tickets.length;

        return tickets[index];
    } 

    function GetPercent(uint256 _amount, uint256 _percent) private pure returns (uint256){
        uint256 prizePool = _amount * _percent / 1e4; // возможно переполнение
        return prizePool;
    }

    //TODO: использовать ли для покупки билетов на незапущенные лотереии
    function GetRunningLottery(uint256 _lotteryNumber) private view returns (Lottery memory) {
        checkIsLotteryExists(_lotteryNumber);
        Lottery memory lottery = lotteries[_lotteryNumber];
        require(lottery.startDate < block.timestamp, "The lottery not started yet");
        require(lottery.endDate > block.timestamp, "The lottery has already ended");
        return lottery;
    }

    function GetEndedLottery(uint256 _lotteryNumber) private view returns (Lottery memory) {
        checkIsLotteryExists(_lotteryNumber);
        Lottery memory lottery = lotteries[_lotteryNumber];
        require(lottery.endDate < block.timestamp, "The lottery is still running");
        return lottery;
    }

    function checkIsLotteryExists(uint256 _lotteryNumber) private view {
        require(lotteries.length >= _lotteryNumber, "Lottery didnt exist");
    }

    function StartNewLottery(uint startDate, uint endDate, uint256 ticketPrice, uint _commissionPercent) public payable {
        require(startDate > block.timestamp && endDate > startDate, "Invalid dates");
        require(ticketPrice > 0, "Ticket price must by higher then 0");
        require(_commissionPercent >= 0 && _commissionPercent < 1e4, "Commission must be in interval between 0 and 99");

        uint256 nextLotteryIndex = lotteries.length;
        lotteries.push();
        Lottery storage lottery = lotteries[nextLotteryIndex];
        lottery.owner = msg.sender;
        lottery.commissionPercent =  _commissionPercent;
        lottery.startDate = startDate;
        lottery.endDate = endDate;
        lottery.ticketPrice = ticketPrice;

        emit LotteryCreated(nextLotteryIndex, msg.sender);
    }

    function FinishLottery(uint256 _lotteryNumber) public payable lotteryExists(_lotteryNumber) {
        Lottery storage lottery = lotteries[_lotteryNumber];
        Ticket memory winnerTicket = GetRandomTicket(lottery.tickets);
        lottery.winnerTicket = winnerTicket;
        lottery.isWinnerChosen = true;

        uint256 overalTicketsPrice = lottery.ticketPrice * lottery.tickets.length; // возможно переполнение
        uint prizePercent = 1e4 - lottery.commissionPercent;

        uint256 prizePool = GetPercent(overalTicketsPrice, prizePercent);
        uint256 commissionAmount = overalTicketsPrice - prizePool;

        bool isTrasferedToWinner = token.transferFrom(payable(address(this)), payable(winnerTicket.owner), prizePool);
        require(isTrasferedToWinner, "Error while transfering prize to winner");

        bool isTrasferedToLotteryOwner = token.transferFrom(payable(address(this)), payable(lottery.owner), commissionAmount);
        require(isTrasferedToLotteryOwner, "Error while transfering commission to lottery owner");

        emit LotteryFinished(_lotteryNumber, winnerTicket.owner, prizePool);
    }

    function BuyTicket(uint256 _lotteryNumber, uint256 _ticketAmount) public payable lotteryExists(_lotteryNumber) {
        Lottery storage lottery = lotteries[_lotteryNumber];

        uint256 latestTicketNumber = lottery.tickets.length;

        for (uint256 i = 0; i < _ticketAmount; i++) {
            lottery.tickets.push(Ticket({
                number: latestTicketNumber++,
                owner: msg.sender 
            }));
        }

        uint256 overalTicketsPrice = lottery.ticketPrice * _ticketAmount; // возможно переполнение
        bool isTrasfered = token.transferFrom(payable(msg.sender), payable(address(this)), overalTicketsPrice);
        require(isTrasfered, "Transfer was not successful");

        emit TicketsSold(_lotteryNumber, msg.sender, _ticketAmount);
    }

    function GetTickets(uint256 _lotteryNumber) public view lotteryExists(_lotteryNumber) returns(uint256[] memory) {
        Lottery memory lottery = lotteries[_lotteryNumber];
        uint256[] memory clientTicketsTemp = new uint256[](lottery.tickets.length);
        uint256 clientTicketCount = 0;

        for (uint256 i = 0; i < lottery.tickets.length; i++) {
            Ticket memory ticket = lottery.tickets[i];
            if(ticket.owner == msg.sender){
                clientTicketsTemp[clientTicketCount] = ticket.number;
                clientTicketCount++;
            }
        }

        uint256[] memory clientTickets = new uint256[](clientTicketCount);
        for (uint256 i = 0; i < clientTicketCount; i++) {
            clientTickets[i] = clientTicketsTemp[i];
        }

        return clientTickets;
    }

    function GetTicketPrice(uint256 _lotteryNumber) public view lotteryExists(_lotteryNumber) returns (uint256){
        Lottery memory lottery = lotteries[_lotteryNumber];
        return lottery.ticketPrice;
    }

    function GetPrizePool(uint256 _lotteryNumber) public view lotteryExists(_lotteryNumber) returns (uint256){
        Lottery memory lottery = lotteries[_lotteryNumber];
        uint256 overalTicketsPrice = lottery.ticketPrice * lottery.tickets.length;
        uint prizePercent = 1e4 - lottery.commissionPercent;
        uint256 prizePool = GetPercent(overalTicketsPrice, prizePercent);
        return prizePool;
    }

    function GetWinner(uint256 _lotteryNumber) public view lotteryExists(_lotteryNumber) returns (Ticket memory){
        Lottery memory lottery = GetEndedLottery(_lotteryNumber);
        require(lottery.isWinnerChosen, "Winner is not chosen yet");
        return lottery.winnerTicket;
    }

    function CheckIsWinned(uint256 _lotteryNumber) public view lotteryExists(_lotteryNumber) returns (bool){
        Lottery memory lottery = GetEndedLottery(_lotteryNumber);
        return lottery.winnerTicket.owner == msg.sender;
    }
}