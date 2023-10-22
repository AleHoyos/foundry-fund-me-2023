// SPDX-License-Identifier: MIT

//Deploy mocks when we are on a local anvil chain.
//Keep track of contract addresses across different chains.
//If we set up this HelperConfig correctly, we will be able to work with a local chain and with any chain we want as well.

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3AggregatorI.sol";

contract HelperConfig is Script {
    //If we are on a local anvil chain, we deploy mock contracts.
    //Otherwise, we grab the existing address from the live networks.

    NetworkConfig public activeNetworkConfig; //Create a variable of type NetworkConfig.

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address.
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetArbitrumConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
        //'chainid' is one of the global variables that Solidity has.
        //We are saying 'if we are on the sepolia chain, use the sepolia config.
        //'if we are not on the sepolia chain, use the anvil config'.
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //All we need in Sepolia is the price feed address.
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
        //With this, we have a way of grabbing the existing address from a live network.
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        //All we need in Sepolia is the price feed address.
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 //Grab this address from Chainlink.
        });
        return ethConfig;
        //With this, we have a way of grabbing the existing address from the Ethereum Mainnet network.
    }

    function getMainnetArbitrumConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        //All we need in Sepolia is the price feed address.
        NetworkConfig memory arbitrumConfig = NetworkConfig({
            priceFeed: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612 //Grab this address from Chainlink.
        });
        return arbitrumConfig;
        //With this, we have a way of grabbing the existing address from the Ethereum Mainnet network.
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //This will also need a price feed address.
        if (activeNetworkConfig.priceFeed != address(0)) {
            //'address(0)' is a way of getting the default value.
            //The purpose of this if is that, if we call this function without it, a new pricefeed will be created. However, if we
            //already deployed one we don't want to deploy a new one.
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
