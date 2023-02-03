# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```


payload will be a base64 encoded stringified json with this format
{
    payloadHash: "md5 of unencrypted content"
    s: {
        p: "encryptedDataString",
    }
    r: {
        p: "encryptedDataString"
    }
}

payloadHash: we prefer md5 instead of sha256 since its shorter. this field is
used to make sure that the same string is being encrypted for both parties.

"s" stands for sender
"r" stands for receiver
"p" stands for payload