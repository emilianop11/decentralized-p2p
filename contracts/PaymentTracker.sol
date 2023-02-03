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
        Escrow associatedEscrow;
        State state;
        Chat associatedChat;
    }

    struct Escrow {
        uint256 _contractId;
        address smartContract;
    }
    struct Chat {
        uint256 chatId;
        address contractId;
    }

    uint public unlockTime;
    address public owner;
    mapping(uint256 => Operation) _operations;
    mapping(address => Operation[]) _addressesToOperations;
    enum State{ PENDING, FINISHED }

    using Counters for Counters.Counter;
    Counters.Counter private _operationIdCounter;

    constructor()  {
        owner = msg.sender;
    }

    function storeInitial(address _sender, address _receiver, uint256 _amount) public {
        require(msg.sender == owner, "Function can only be called by owner");
        _operationIdCounter.increment();
        uint256 operationId = _operationIdCounter.current();

        _operations[operationId].operationId = operationId;
        _operations[operationId].sender= _sender;
        _operations[operationId].receiver= _receiver;
        _operations[operationId].amount= _amount;
        _operations[operationId].state = State.PENDING;
        _addressesToOperations[msg.sender].push(_operations[operationId]);
    }

    function completeOperation(uint256 _operationId) public {
        Operation storage op = _operations[_operationId];
        require(op.receiver == msg.sender, "operation can only be completed by receiver of the funds");
        op.state = State.FINISHED;
    }
}
