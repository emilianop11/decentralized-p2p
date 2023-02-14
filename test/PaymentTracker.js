const { expect } = require("chai");
const {ParseSolidityStruct} = require("solidity-struct-parser");

describe('Helper', function () {
  beforeEach(async function() {
    [owner, wallet1, wallet2, wallet3, wallet4, walletHacker] = await ethers.getSigners();
    AnyToken = await ethers.getContractFactory('Any', owner);
    anyToken = await AnyToken.deploy();
    PaymentsContract = await ethers.getContractFactory('PaymentTracker', owner);
    paymentsContract = await PaymentsContract.deploy(anyToken.address);

    anyToken.connect(owner).transfer(wallet1.address, 1000);
    anyToken.connect(owner).transfer(wallet2.address, 1000);
    anyToken.connect(owner).transfer(wallet3.address, 1000);
    anyToken.connect(owner).transfer(wallet4.address, 1000);

    await anyToken.connect(wallet1).approve(
      paymentsContract.address,
      5000
    );
    await anyToken.connect(wallet2).approve(
      paymentsContract.address,
      5000
    );
    await anyToken.connect(wallet3).approve(
      paymentsContract.address,
      5000
    );
    await anyToken.connect(wallet4).approve(
      paymentsContract.address,
      5000
    );
  });
  describe('offers', function () {
    it('should create offer', async function () {
      await paymentsContract.connect(wallet1).createOffer(
        0, 1000, 1000, "banco nacion"
      );

      const offers1 = await paymentsContract.connect(wallet1).getOffersForAddress();
      expect(ParseSolidityStruct(offers1)).to.eql([
        {
          "createdAt": ParseSolidityStruct(offers1)[0].createdAt,
          "createdBy": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
          "maxAmount": 1000,
          "minAmount": 1000,
          "transactionType": 0,
          "offerId": 1,
          "paymentMethod": "banco nacion"
        }
      ])

      await paymentsContract.connect(wallet1).createOffer(
        1, 1000, 10000, "banco nacion"
      );

      const offers2 = await paymentsContract.connect(wallet1).getOffersForAddress();
      expect(ParseSolidityStruct(offers2)).to.eql([
        {
          "createdAt": ParseSolidityStruct(offers2)[0].createdAt,
          "createdBy": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
          "maxAmount": 1000,
          "minAmount": 1000,
          "offerId": 1,
          "transactionType": 0,
          "paymentMethod": "banco nacion"
        },
        {
          "createdAt": ParseSolidityStruct(offers2)[1].createdAt,
          "createdBy": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
          "maxAmount": 10000,
          "minAmount": 1000,
          "offerId": 2,
          "transactionType": 1,
          "paymentMethod": "banco nacion"
        }
      ])


      await expect(paymentsContract.connect(wallet3).createTransaction(wallet3.address, wallet4.address, 100, "anything", 1)).to.be.revertedWith("offer is not associated to this sender address");

      await paymentsContract.connect(wallet1).createTransaction(wallet1.address, wallet4.address, 100, "anything", 1);
      await paymentsContract.connect(wallet2).createTransaction(wallet2.address, wallet1.address, 100, "anything", 1);


      const opsForAddress1 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres1 = ParseSolidityStruct(opsForAddress1)
      expect(parsedOpsForAddres1).to.eql([
        {
        "createdAt": parsedOpsForAddres1[0].createdAt,
        "transactionId":1,
        "sender":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "receiver":"0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
        "amount":100,
        "offerId": 1,
        "recipientData":"anything",
        "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
        "state":0,
        "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]},
        {
          "createdAt": parsedOpsForAddres1[1].createdAt,
          "transactionId":2,
          "sender":"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
          "receiver":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
          "amount":100,
          "offerId": 1,
          "recipientData":"anything",
          "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
          "state":0,
          "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]}
      
      ])
    })
  });
  
  describe('transactions', function () {
    it('should check transfers when transaction was not created created by owner', async function () {

      expect(await anyToken.balanceOf(wallet1.address)).to.equal(1000);
      expect(await anyToken.balanceOf(wallet2.address)).to.equal(1000);
      expect(await anyToken.balanceOf(wallet3.address)).to.equal(1000);
      // this is passing wallet3 as sender. we need to check that its not taken into consideration
      await paymentsContract.connect(wallet1).createTransaction(wallet3.address, wallet2.address, 100, "anything", 0);
      expect(await anyToken.balanceOf(wallet1.address)).to.equal(900);
      expect(await anyToken.balanceOf(wallet2.address)).to.equal(1100);
      expect(await anyToken.balanceOf(wallet3.address)).to.equal(1000);
      // above we can effectively see that the amount was discounted from wallet1

      const opsForAddress1 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres1 = ParseSolidityStruct(opsForAddress1)
      expect(parsedOpsForAddres1).to.eql([
        {
        "createdAt": parsedOpsForAddres1[0].createdAt,
        "transactionId":1,
        "sender":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "receiver":"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "amount":100,
        "offerId": 0,
        "recipientData":"anything",
        "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
        "state":0,
        "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]}])

      expect(parsedOpsForAddres1[0].sender).to.equal(wallet1.address)
      expect(parsedOpsForAddres1[0].receiver).to.equal(wallet2.address)
      expect(parsedOpsForAddres1[0].state).to.equal(0)
      const opsForAddress2 = await paymentsContract.connect(wallet2).getTransactionsForAddress();
      const parsedOpsForAddres2 = ParseSolidityStruct(opsForAddress2)
      expect(parsedOpsForAddres2).to.eql([
        {"transactionId":1,
        "createdAt": parsedOpsForAddres2[0].createdAt,
        "sender":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "receiver":"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "amount":100,
        "offerId": 0,
        "recipientData":"anything",
        "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
        "state":0,
        "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]}])
      expect(parsedOpsForAddres2[0].sender).to.equal(wallet1.address)
      expect(parsedOpsForAddres2[0].receiver).to.equal(wallet2.address)
      expect(parsedOpsForAddres2[0].state).to.equal(0)
        
      await expect(paymentsContract.connect(wallet1).completeTransaction(1)).to.be.revertedWith("transaction can only be completed by receiver of the funds");
      const opsForAddress3 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres3 = ParseSolidityStruct(opsForAddress3)
      expect(parsedOpsForAddres3[0].state).to.equal(0)

      await paymentsContract.connect(wallet2).completeTransaction(1)
      const opsForAddress4 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres4 = ParseSolidityStruct(opsForAddress4)
      expect(parsedOpsForAddres4[0].state).to.equal(1)
    });

    it('should check transfers when transaction was created by owner', async function () {

      expect(await anyToken.balanceOf(wallet1.address)).to.equal(1000);
      expect(await anyToken.balanceOf(wallet2.address)).to.equal(1000);
      await paymentsContract.connect(owner).createTransaction(wallet1.address, wallet2.address, 100, "anything", 0);
      expect(await anyToken.balanceOf(wallet1.address)).to.equal(900);
      expect(await anyToken.balanceOf(wallet2.address)).to.equal(1100);

      const opsForAddress1 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres1 = ParseSolidityStruct(opsForAddress1)
      expect(parsedOpsForAddres1).to.eql([
        {"transactionId":1,
        "createdAt": parsedOpsForAddres1[0].createdAt,
        "sender":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "receiver":"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "amount":100,
        "offerId": 0,
        "recipientData":"anything",
        "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
        "state":0,
        "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]}])

      expect(parsedOpsForAddres1[0].sender).to.equal(wallet1.address)
      expect(parsedOpsForAddres1[0].receiver).to.equal(wallet2.address)
      expect(parsedOpsForAddres1[0].state).to.equal(0)
      const opsForAddress2 = await paymentsContract.connect(wallet2).getTransactionsForAddress();
      const parsedOpsForAddres2 = ParseSolidityStruct(opsForAddress2)
      expect(parsedOpsForAddres2).to.eql([
        {"transactionId":1,
        "createdAt": parsedOpsForAddres2[0].createdAt,
        "sender":"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "receiver":"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "amount":100,
        "offerId": 0,
        "recipientData":"anything",
        "associatedEscrow":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"],
        "state":0,
        "associatedChat":[{"_hex":"0x00","_isBigNumber":true},"0x0000000000000000000000000000000000000000"]}])
      expect(parsedOpsForAddres2[0].sender).to.equal(wallet1.address)
      expect(parsedOpsForAddres2[0].receiver).to.equal(wallet2.address)
      expect(parsedOpsForAddres2[0].state).to.equal(0)
        
      await expect(paymentsContract.connect(wallet1).completeTransaction(1)).to.be.revertedWith("transaction can only be completed by receiver of the funds");
      const opsForAddress3 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres3 = ParseSolidityStruct(opsForAddress3)
      expect(parsedOpsForAddres3[0].state).to.equal(0)

      await paymentsContract.connect(wallet2).completeTransaction(1)
      const opsForAddress4 = await paymentsContract.connect(wallet1).getTransactionsForAddress();
      const parsedOpsForAddres4 = ParseSolidityStruct(opsForAddress4)
      expect(parsedOpsForAddres4[0].state).to.equal(1)
    });
  });
});