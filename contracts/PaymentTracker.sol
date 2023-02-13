// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PaymentTracker {
    enum OperationType{ SELL_CRYPTO, BUY_CRYPTO }

    struct Offer {
        uint createdAt;
        address createdBy;
        uint256 offerId;
        OperationType opType;
        uint256 maxAmount;
        uint256 minAmount;
        string paymentMethod;
    }

    struct Operation {
        uint createdAt;
        uint256 operationId;
        uint256 offerId;
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
    mapping(uint256 => Offer) _offers;
    mapping(address => uint256[]) _addressesToOperations;
    mapping(address => uint256[]) _addressesToOffers;
    address warrantyTokenAddress;
    enum State{ PENDING, FINISHED }

    using Counters for Counters.Counter;
    Counters.Counter private _operationIdCounter;
    Counters.Counter private _offerIdCounter;

    constructor(address _warrantyTokenAddress)  {
        owner = msg.sender;
        warrantyTokenAddress = _warrantyTokenAddress;
    }

    function createOffer(
        OperationType opType,
        uint256 minAmount,
        uint256 maxAmount,
        string calldata paymentMethod
    ) public {
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        _offers[offerId].offerId = offerId;
        _offers[offerId].createdAt = block.timestamp;
        _offers[offerId].createdBy = msg.sender;
        _offers[offerId].opType = opType;
        _offers[offerId].maxAmount = maxAmount;
        _offers[offerId].minAmount = minAmount;
        _offers[offerId].paymentMethod = paymentMethod;
        _addressesToOffers[msg.sender].push(offerId);
    }

    function createOperation(address _sender, address _receiver, uint256 _amount, string calldata _recipientData, uint256 offerId) public {
        if(msg.sender != owner) {
            _sender = msg.sender;
        }
        require(offerId == 0 || _offers[offerId].createdBy == _sender  || _offers[offerId].createdBy == _receiver, "offer is not associated to this sender address");

        ERC20(warrantyTokenAddress).transferFrom(_sender, _receiver, _amount);
        _operationIdCounter.increment();
        uint256 operationId = _operationIdCounter.current();
        _operations[operationId].operationId = operationId;
        _operations[operationId].offerId = offerId;
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

    function getOffersForAddress() external view returns (Offer[] memory) {
        uint256[] storage offerIds = _addressesToOffers[msg.sender];
        Offer[] memory offers = new Offer[](offerIds.length);
        for (uint i = 0; i < offerIds.length; i++) {
            uint256 offerId = offerIds[i];
            Offer storage op = _offers[offerId];
            offers[i] = op;
        }
        return offers;
    }
}
