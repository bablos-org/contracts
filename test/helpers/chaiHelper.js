const BigNumber = web3.BigNumber
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const INVALID_OPCODE_ERROR = 'VM Exception while processing transaction: invalid opcode';
const REVERT_ERROR = 'VM Exception while processing transaction: revert';

module.exports = { should, INVALID_OPCODE_ERROR, REVERT_ERROR };