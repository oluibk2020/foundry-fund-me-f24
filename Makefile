-include .env

build:; forge build

forge-test:; forge test

remove-cache:; rm -rf artifacts cache

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --broadcast --rpc-url ${SEPOLIA_RPC_URL} --private-key ${SEPOLIA_PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv