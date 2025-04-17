// scripts/verify.js
const { run } = require("hardhat");

async function main() {
    console.log(`Verifying NebulaCoin at: ${process.env.NEBULACOIN_CONTRACT_ADDRESS}`);
    await run("verify:verify", {
        address: process.env.NEBULACOIN_CONTRACT_ADDRESS,
        // constructorArguments: ["NebulaCoin", "NEB"],
        contract: "contracts/NebulaCoin.sol:NebulaCoin"
    });

    console.log(`Verifying FluxToken at: ${process.env.FLUXTOKEN_CONTRACT_ADDRESS}`);
    await run("verify:verify", {
        address: process.env.FLUXTOKEN_CONTRACT_ADDRESS,
        // constructorArguments: ["FluxToken", "FLX"],
        contract: "contracts/FluxToken.sol:FluxToken"
    });

    console.log(`Verifying LPToken at: ${process.env.LPTOKEN_CONTRACT_ADDRESS}`);
    await run("verify:verify", {
        address: process.env.LPTOKEN_CONTRACT_ADDRESS,
        // constructorArguments: ["Uniswap Clone LP Token", "ULP"],
        contract: "contracts/LPToken.sol:LPToken"
    });

    console.log(`Verifying DEX at: ${process.env.DEX_CONTRACT_ADDRESS}`);
    await run("verify:verify", {
        address: process.env.DEX_CONTRACT_ADDRESS,
        constructorArguments: [
            process.env.NEBULACOIN_CONTRACT_ADDRESS,
            process.env.FLUXTOKEN_CONTRACT_ADDRESS,
            process.env.LPTOKEN_CONTRACT_ADDRESS,
        ],
        contract: "contracts/UniswapDEX.sol:UniswapDEX"
    });
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
