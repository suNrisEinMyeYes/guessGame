// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.6.0

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// File contracts/Game.sol

pragma solidity ^0.8.4;

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
