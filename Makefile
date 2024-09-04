-include .env


clean :; forge clean

build :; forge build

test :; forge test --ffi

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verify  -vvvv
endif

ifeq ($(findstring --network tenderly,$(ARGS)),--network tenderly)
	NETWORK_ARGS := --rpc-url $(TENDERLY_VIRTUAL_TESTNET_RPC_URL) --private-key $(TENDERLY_PRIVATE_KEY) --etherscan-api-key $(TENDERLY_ACCESS_TOKEN) --broadcast --verify --verifier-url $(TENDERLY_VERIFIER_URL) --slow -vvvv
endif

ifeq ($(findstring --network mainnet,$(ARGS)),--network mainnet)
	NETWORK_ARGS := --rpc-url $(MAINNET_RPC_URL) --private-key $(PRIVATE_KEY_MAINNET) --broadcast --etherscan-api-key $(ETHERSCAN_API_KEY) --verify -vvvv
endif

deploy-v1:; forge create src/MyToken.sol:MyToken \
--private-key $(TENDERLY_PRIVATE_KEY) \
--rpc-url $(TENDERLY_VIRTUAL_TESTNET_RPC_URL) \
--etherscan-api-key $(TENDERLY_ACCESS_TOKEN) \
--verify \
--verifier-url $(TENDERLY_VERIFIER_URL)

deploy-v1-with-script :; forge script script/deployToken.s.sol $(NETWORK_ARGS)
deploy-proxy-with-script :; forge script script/deployProxy.s.sol:DeployUUPSProxy $(NETWORK_ARGS)
mint-tokens-with-script :; forge script script/mintToken.s.sol:MintPetal $(NETWORK_ARGS)
deploy-v2-with-script :; forge script script/deployV2.s.sol:DeployV2AndUpgrade --ffi $(NETWORK_ARGS)