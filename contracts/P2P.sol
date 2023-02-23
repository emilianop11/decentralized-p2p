// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract P2P {
    enum TransactionType{ SELL_CRYPTO, BUY_CRYPTO }

    struct Offer {
        uint createdAt;
        address createdBy;
        uint256 offerId;
        TransactionType transactionType;
        uint256 maxAmount;
        uint256 minAmount;
        bool isActive;
        string metadata;
    }

    struct Transaction {
        uint createdAt;
        uint256 transactionId;
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
    mapping(uint256 => Transaction) _transactions;
    mapping(uint256 => Offer) _offers;
    mapping(address => uint256[]) _addressesToTransactions;
    mapping(address => uint256[]) _addressesToOffers;
    address warrantyTokenAddress;
    enum State{ PENDING, FINISHED }

    using Counters for Counters.Counter;
    Counters.Counter private _transactionIdCounter;
    Counters.Counter private _offerIdCounter;

    constructor(address _warrantyTokenAddress)  {
        owner = msg.sender;
        warrantyTokenAddress = _warrantyTokenAddress;
    }

    function deactivateOffer(uint256 offerId) public {
        require(_offers[offerId].createdBy == msg.sender, "offer can only be deactived by creator");
        _offers[offerId].isActive = false;
    }

    function createOffer(
        TransactionType transactionType,
        uint256 minAmount,
        uint256 maxAmount,
        string calldata metadata
    ) public {
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        _offers[offerId].offerId = offerId;
        _offers[offerId].createdAt = block.timestamp;
        _offers[offerId].createdBy = msg.sender;
        _offers[offerId].isActive = true;
        _offers[offerId].transactionType = transactionType;
        _offers[offerId].maxAmount = maxAmount;
        _offers[offerId].minAmount = minAmount;
        _offers[offerId].metadata = metadata;
        _addressesToOffers[msg.sender].push(offerId);
    }

    function createTransaction(address _sender, address _receiver, uint256 _amount, string calldata _recipientData, uint256 offerId) public {
        if(msg.sender != owner) {
            _sender = msg.sender;
        }

        if (offerId != 0) {
            require(_offers[offerId].isActive, "Offer must be active");
            require(_amount <= _offers[offerId].maxAmount && _amount >= _offers[offerId].minAmount, "amount must be within offer max and min");

            if (_offers[offerId].transactionType == TransactionType.SELL_CRYPTO) {
                require(_offers[offerId].createdBy == _sender,  "offer is of sell type, offer must have been created by sender");
            }

            if (_offers[offerId].transactionType == TransactionType.BUY_CRYPTO) {
                require(_offers[offerId].createdBy == _receiver,  "offer is of buy type, offer must have been created by receiver");
            }
        }
        

        ERC20(warrantyTokenAddress).transferFrom(_sender, _receiver, _amount);
        _transactionIdCounter.increment();
        uint256 transactionId = _transactionIdCounter.current();
        _transactions[transactionId].transactionId = transactionId;
        _transactions[transactionId].offerId = offerId;
        _transactions[transactionId].sender = _sender;
        _transactions[transactionId].receiver = _receiver;
        _transactions[transactionId].amount = _amount;
        _transactions[transactionId].state = State.PENDING;
        _transactions[transactionId].recipientData = _recipientData;
        _transactions[transactionId].createdAt = block.timestamp;
        _addressesToTransactions[_sender].push(transactionId);
        _addressesToTransactions[_receiver].push(transactionId);

    }

    function completeTransaction(uint256 _transactionId) public {
        Transaction storage transaction = _transactions[_transactionId];
        require(transaction.receiver == msg.sender, "transaction can only be completed by receiver of the funds");
        _transactions[_transactionId].state = State.FINISHED;
    }

    function getTransactionsForAddress() external view returns (Transaction[] memory) {
        uint256[] storage transactionIds = _addressesToTransactions[msg.sender];
        Transaction[] memory transactions = new Transaction[](transactionIds.length);
        for (uint i = 0; i < transactionIds.length; i++) {
            uint256 transactionId = transactionIds[i];
            Transaction storage transaction = _transactions[transactionId];
            transactions[i] = transaction;
        }
        return transactions;
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
