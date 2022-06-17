//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GuessGame is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _gamesIds;

  uint256 public variableToTest;

  struct Game {
    uint256 timeFinished;
    uint256 amountOfPartcipants;
    uint256 amountOfParticipantsAvailable;
    uint256 bid;
    uint256 prizePool;
    address[] participants;
  }

  struct Players {
    uint256 balance;
  }

  struct searchTool {
    uint256 lastIndexInitialized;
    uint256 maxAbs;
    uint256 indexOfArrayOfmaxAbs;
  }

  mapping(uint256 => Game) idToGame;
  mapping(uint256 => searchTool) private search;
  mapping(address => uint256) balance;
  mapping(uint256 => mapping(address => uint256)) gameToAddressToNumber;

  event gameCreated(
    uint256 gameId,
    uint256 bid,
    uint256 participantsAvailable,
    uint256 startTime
  );
  event gameFinished();
  event newParticipant(uint256 gameId, address participant, uint256 number);

  constructor() {}

  function createGame(uint256 _number, uint256 _amountOfParticipants)
    external
    payable
  {
    require(msg.value > 0, "value is not sufficiant");
    require(_number <= 100, "incorrect value");
    address[] memory tmp = new address[](1);
    tmp[0] = msg.sender;
    Game memory game = Game(
      block.timestamp + 5 minutes,
      1,
      _amountOfParticipants,
      msg.value,
      msg.value,
      tmp
    );
    _gamesIds.increment();
    idToGame[_gamesIds.current()] = game;
    gameToAddressToNumber[_gamesIds.current()][msg.sender] = _number;

    emit gameCreated(
      _gamesIds.current(),
      msg.value,
      _amountOfParticipants,
      block.timestamp
    );
  }

  function finishGame(uint256 _id) external {
    require(
      idToGame[_id].timeFinished < block.timestamp ||
        (idToGame[_id].amountOfPartcipants ==
          idToGame[_id].amountOfParticipantsAvailable &&
          idToGame[_id].amountOfParticipantsAvailable != 0),
      "not time yet to finish"
    );
    uint256 rnd = _getRandomNum(_id);
    variableToTest = rnd;
    uint256 numberOfWinners = (idToGame[_id].amountOfPartcipants * 3) / 10;
    if (numberOfWinners == 0) numberOfWinners++;
    address[] memory winners = new address[](numberOfWinners);
    uint256 abs;
    search[_id].maxAbs = 101;
    for (
      uint256 index = 0;
      index < idToGame[_id].amountOfPartcipants;
      index++
    ) {
      abs = gameToAddressToNumber[_id][idToGame[_id].participants[index]] > rnd
        ? gameToAddressToNumber[_id][idToGame[_id].participants[index]] - rnd
        : rnd - gameToAddressToNumber[_id][idToGame[_id].participants[index]];
      if (search[_id].lastIndexInitialized < numberOfWinners) {
        winners[index] = (idToGame[_id].participants[index]);
        if (search[_id].maxAbs < abs)
          search[_id].maxAbs = gameToAddressToNumber[_id][
            idToGame[_id].participants[index]
          ];
        search[_id].maxAbs = abs;
        search[_id].indexOfArrayOfmaxAbs = search[_id].lastIndexInitialized;
        search[_id].lastIndexInitialized++;
      } else {
        if (search[_id].maxAbs > abs) {
          winners[search[_id].indexOfArrayOfmaxAbs] = idToGame[_id]
            .participants[index];
          //--
          for (uint256 j = 0; j < numberOfWinners; j++) {
            abs = gameToAddressToNumber[_id][winners[j]] > rnd
              ? gameToAddressToNumber[_id][winners[j]] - rnd
              : rnd - gameToAddressToNumber[_id][winners[j]];

            if (search[_id].maxAbs >= abs) {
              search[_id].maxAbs = abs;
              search[_id].indexOfArrayOfmaxAbs = j;
            }
          }
        }
      }
    }
    for (uint256 tmp = 0; tmp < numberOfWinners; tmp++) {
      balance[winners[tmp]] = idToGame[_id].prizePool / numberOfWinners;
    }
    idToGame[_id].prizePool = 0;
    emit gameFinished();
  }

  function Withdraw() external nonReentrant {
    payable(msg.sender).transfer(balance[msg.sender]);
    balance[msg.sender] = 0;
  }

  function guessNumber(uint256 _gameId, uint256 _number) external payable {
    require(msg.value == idToGame[_gameId].bid, "incorrect value");
    require(idToGame[_gameId].timeFinished >= block.timestamp, "game finished");
    require(
      idToGame[_gameId].amountOfPartcipants <
        idToGame[_gameId].amountOfParticipantsAvailable ||
        idToGame[_gameId].amountOfParticipantsAvailable == 0,
      "Not enough places"
    );
    idToGame[_gameId].amountOfPartcipants++;
    idToGame[_gameId].participants.push(msg.sender);
    gameToAddressToNumber[_gameId][msg.sender] = _number;
    idToGame[_gameId].prizePool += msg.value;

    emit newParticipant(_gameId, msg.sender, _number);
  }

  function _getRandomNum(uint256 _gameId) private view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            block.difficulty,
            block.timestamp,
            idToGame[_gameId].amountOfPartcipants
          )
        )
      ) % 100;
  }

  function getBalance() external view returns (uint256) {
    return balance[msg.sender];
  }

  function getGame(uint256 _id) external view returns (Game memory) {
    return idToGame[_id];
  }
}
