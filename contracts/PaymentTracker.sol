// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PaymentTracker {
    struct Operation {
        uint createdAt;
        uint256 operationId;
        address sender;
        address receiver;
        uint256 amount;
        string recipientData;
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

   
    address public owner;
    mapping(uint256 => Operation) _operations;
    mapping(address => uint256[]) _addressesToOperations;
    address warrantyTokenAddress;
    enum State{ PENDING, FINISHED }

    using Counters for Counters.Counter;
    Counters.Counter private _operationIdCounter;

    constructor(address _warrantyTokenAddress)  {
        owner = msg.sender;
        warrantyTokenAddress = _warrantyTokenAddress;
    }

    function create(address _sender, address _receiver, uint256 _amount, string calldata _recipientData) public {
        if(msg.sender != owner) {
            _sender = msg.sender;
        }

        ERC20(warrantyTokenAddress).transferFrom(_sender, _receiver, _amount);
        _operationIdCounter.increment();
        uint256 operationId = _operationIdCounter.current();
        _operations[operationId].operationId = operationId;
        _operations[operationId].sender = _sender;
        _operations[operationId].receiver = _receiver;
        _operations[operationId].amount = _amount;
        _operations[operationId].state = State.PENDING;
        _operations[operationId].recipientData = _recipientData;
        _operations[operationId].createdAt = block.timestamp;
        _addressesToOperations[_sender].push(operationId);
        _addressesToOperations[_receiver].push(operationId);

    }

    function completeOperation(uint256 _operationId) public {
        Operation storage op = _operations[_operationId];
        require(op.receiver == msg.sender, "operation can only be completed by receiver of the funds");
        _operations[_operationId].state = State.FINISHED;
    }

    function getOperationsForAddress() external view returns (Operation[] memory) {
        uint256[] storage operationIds = _addressesToOperations[msg.sender];
        Operation[] memory operations = new Operation[](operationIds.length);
        for (uint i = 0; i < operationIds.length; i++) {
            uint256 operationId = operationIds[i];
            Operation storage cont = _operations[operationId];
            operations[i] = cont;
        }
        return operations;
    }
}
