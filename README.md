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
    s: {
        p: "encryptedDataString"
    }
    r: {
        p: "encryptedDataString"
    }
}

"s" stands for sender
"r" stands for receiver
"p" stands for payload