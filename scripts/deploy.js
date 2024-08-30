
const hre = require("hardhat");
const { NFT_COLLECTION_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  const FakeNFTMarketplace = await hre.ethers.getContractFactory("FakeNFTMarketplace");
  const fakeNFTMarketplace = await FakeNFTMarketplace.deploy()
  await fakeNFTMarketplace.waitForDeployment()

  console.log("FakeNFTMarketPlace contract deployed at",fakeNFTMarketplace.target);

  const DAO = await  hre.ethers.getContractFactory("DAO");
  const Dao = await DAO.deploy(fakeNFTMarketplace.target,
    NFT_COLLECTION_CONTRACT_ADDRESS,
    {value : hre.ethers.parseEther("0.001")}
    )
  await Dao.waitForDeployment()

  console.log("DAO contract deployed at",Dao.target);

  await hre.run("verify:verify",{
    address : Dao.target,
    constructorArguments : [fakeNFTMarketplace.target,
      NFT_COLLECTION_CONTRACT_ADDRESS
      ]
  })

  await hre.run("verify:verify",{
    address : fakeNFTMarketplace.target,
    constructorArguments : []
  })
  
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
