## Upgradeable ERC20 Token

### Configure project

Set up a new foundry project.

In terminal within the project's root folder, run the command:

```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-foundry-upgrades --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

Add the following lines to the `remappings.txt` file:

```
@openzeppelin/contracts/=lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/
@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
```

For deployment on test or mainnet, define the "RPC_ENDPOINT_URL" in `foundry.toml` and "PRIVATE_KEY" in the `.env` files.

### Build project

Run the following command in the root folder

```bash
forge build
```

### Test project

Run the following command in the root folder

```bash
forge test --ffi
```

> The `--ffi` flag is included in order to run external scripts our code needs to access.

### Deploy proxy and v1 Token

Make sure the environment variables are set and run the following scripts

```bash
forge script script/deployToken.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
```

**Important:** Now, before running the next command, you'll need to update the `_implementation` variable in the `script/deployProxy.s.sol` script with your deployed smart contract address (e.g., token address) from the previous step.

Then, deploy the proxy through the following command

```bash
forge script script/deployProxy.s.sol:DeployUUPSProxy --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
```

### Verify contracts on Etherscan

To verify your contracts, both the token and proxy, on Etherscan, simply add the --etherscan-api-key YOUR_ETHERSCAN_API_KEY --verify flags to the end of the commands above.

:::note
You will need an account on [Etherscan](https://etherscan.io) in order to create a API key for verification of the contracts.
:::

## Resources

Find a guide [here](https://www.quicknode.com/guides/ethereum-development/smart-contracts/how-to-create-and-deploy-an-upgradeable-erc20-token).