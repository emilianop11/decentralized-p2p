//USDC 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174

const main = async () => {
  const p2pContractFactory = await hre.ethers.getContractFactory('P2P');
  const p2pContract = await p2pContractFactory.deploy("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174");
  await p2pContract.deployed();
  console.log('Contract Address:', p2pContract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

runMain();