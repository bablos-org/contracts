const BablosToken = artifacts.require('./tokens/BablosToken.sol');

const name = "Bablos Token";
const symbol = "BABLOS";
const decimals = 0;
const totalSupply = 2 * 10**6;

module.exports = function (deployer, network, accounts) {
    return deployer
        .then(() => {
            return deployer.deploy(
                BablosToken,
                name,
                symbol,
                decimals,
                totalSupply);
        });
};