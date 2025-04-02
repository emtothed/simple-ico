# ICO Contracts

A simple smart contract implementation for a sample token launche and ICO built with Solidity and Foundry.

## Overview

This project implements:
- ERC20 token contract (SampleToken)
- ICO contract for token sales
- USDT integration for testnest

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (>= v16)

## Installation

```bash
git clone https://github.com/emtothed/simple-ico
cd simple-ico
forge install
```

## Building

```bash
forge build
```

## Testing

```bash
forge test
```

## Deployment

The deployment script is located in `script/DeployICO.s.sol`. To deploy:

```bash
forge script script/DeployICO.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## Deployed Contract Addresses

Sepolia (11155111): [TokenICO](https://sepolia.etherscan.io/address/0x6D74b5430779a14c0d0C9149fB36B709079E74Aa)




## License

MIT
