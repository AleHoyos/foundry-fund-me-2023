-include .env

build:; forge build
dploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url https://eth-sepolia.g.alchemy.com/v2/pRcgn69cVjxEQOk0jB9p4jdpfD5_OD4tx --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
