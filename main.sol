Here is an example of what the contract might look like:

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Poker {
    enum Phase { PreFlop, Flop, Turn, River, Showdown }
    Phase public currentPhase = Phase.PreFlop;

    struct Player {
        address payable addr;
        uint256 balance;
        uint256 bet;
        uint8[2] cards;
        bool folded;
    }

    Player[] public players;
    uint256 public pot;

    event DealCards(address indexed player, uint8[2] cards);
    event Bet(address indexed player, uint256 amount);
    event Fold(address indexed player);
    event Showdown(address indexed player, uint8[2] cards, uint256 hand);

    function dealCards(uint8[2] memory cards) public {
        require(players.length < 3, "Game full");
        require(currentPhase == Phase.PreFlop, "Can't deal cards now");
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == msg.sender) {
                revert("Already dealt cards");
            }
        }
        players.push(Player({
            addr: payable(msg.sender),
            balance: msg.value,
            bet: 0,
            cards: cards,
            folded: false
        }));
        if (players.length == 2) {
            currentPhase = Phase.Flop;
        }
        emit DealCards(msg.sender, cards);
    }

    function bet() public payable {
        require(currentPhase != Phase.Showdown, "Game over");
        Player storage player = findPlayer();
        require(msg.sender == player.addr, "Not your turn");

        player.balance += player.bet;
        player.bet = msg.value;
        player.balance -= player.bet;
        pot += msg.value;
        emit Bet(msg.sender, msg.value);

        nextPlayer();
    }
