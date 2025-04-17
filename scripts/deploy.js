
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
    await hre.run("compile");
    console.log("Deploying Contract...");

    const NebulaCoin = await hre.ethers.getContractFactory("NebulaCoin");
    const nebulaCoin = await NebulaCoin.deploy();
    await nebulaCoin.waitForDeployment();
    console.log("NebulaCoin deployed to:", await nebulaCoin.getAddress());

    const FluxToken = await hre.ethers.getContractFactory("FluxToken");
    const fluxToken = await FluxToken.deploy();
    await fluxToken.waitForDeployment();
    console.log("FluxToken deployed to:", await fluxToken.getAddress());

    const LPToken = await hre.ethers.getContractFactory("LPToken");
    const lpToken = await LPToken.deploy();
    await lpToken.waitForDeployment();
    console.log("LPToken deployed to:", await lpToken.getAddress());

    const DEX = await hre.ethers.getContractFactory("UniswapDEX");
    const dex = await DEX.deploy(await nebulaCoin.getAddress(), await fluxToken.getAddress(), await lpToken.getAddress());
    await dex.waitForDeployment();
    console.log("DEX deployed to:", await dex.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
