// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PaymentTracker {
    struct Operation {
        uint256 operationId;
        address sender;
        address receiver;
        uint256 amount;
        string payload;
        uint256 escrowContractId;
        State state;
        Chat associatedChat;
    }

    struct Chat {
        uint256 chatId;
        address contractId;
    }

    uint public unlockTime;
    address public owner;
    mapping(uint256 => Operation) operations;
    mapping(address => Operation[]) addressesToOperations;
    enum State{ PENDING, FINISHED }

    using Counters for Counters.Counter;
    Counters.Counter private _contractIdCounter;

    constructor()  {
        owner = msg.sender;
    }

    function storeInitial(address _sender, address _receiver, uint256 _amount) public {
        require(msg.sender == owner, "Function can only be called by owner");
        _contractIdCounter.increment();
        uint256 operationId = _contractIdCounter.current();

        operations[operationId].operationId = operationId;
        operations[operationId].sender= _sender;
        operations[operationId].receiver= _receiver;
        operations[operationId].amount= _amount;
        operations[operationId].state = State.PENDING;
        addressesToOperations[msg.sender].push(operations[operationId]);
    }

    function completeOperation(uint256 _operationId) public {
        Operation storage op = operations[_operationId];
        require(op.receiver == msg.sender, "operation can only be completed by receiver of the funds");
        op.state = State.FINISHED;
    }
}
