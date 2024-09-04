## Upgradeable ERC20 Token

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

## Deployment and Verification

Currently, verification is via foundry script can be buggy. see this issue https://github.com/foundry-rs/foundry/issues/7466

Very important to have set etherscan params in `foundry.toml`. See this [link](https://book.getfoundry.sh/reference/config/etherscan) for more. Quick tip `foundry.toml` can also reference `.env` vars.

There are two options to deploy and verify

1. forge create
2. forge script

### forge create

This approach has the disadvantage that constructor args have to be submitted via CLI.

```bash
make deploy-v1
```

### forge script

```bash
make deploy-v1-with-script ARGS="--network tenderly"
```

Note that even with a response like that ...

```
Encountered an error verifying this contract:
Response: `NOTOK`
Details: `{"id":"df818a97-2afc-4776-b3e7-d17da61610b7","msg":"not found","slug":"not_found"}`
make: *** [deploy-v1-with-script] Error 1
```

The verification most presumably worked.

### Deploy proxy and v1 Token

First deploy the v1 token contract, like seen before

```bash
make deploy-v1-with-script ARGS="--network tenderly"
```

**Important:** Now, before running the next command, you'll need to update the `_implementation` variable in the `script/deployProxy.s.sol` script with your deployed smart contract address (e.g., token address) from the previous step.

Then, deploy the proxy through the following command

```bash
make deploy-proxy-with-script ARGS="--network tenderly"
```

## Resources

Find a guide [here](https://www.quicknode.com/guides/ethereum-development/smart-contracts/how-to-create-and-deploy-an-upgradeable-erc20-token).

[Tenderly SC Verification](https://docs.tenderly.co/contract-verification/foundry#verify-contracts-from-foundry-scripts-with-forge-script)

## How this project was setup

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
