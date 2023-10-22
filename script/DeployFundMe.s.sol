// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //Before the Broadcast, we create new 'HelperConfig'.
        //Everything that happens before the broadcast will not be sent as a real transaction.
        //Everything that happens after the broadcast will be sent as a real transaction.
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); //Here we are getting the ethUsdPriceFeed.

        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed); //Now that we have the ethUsdPriceFeed, we put it in here.
        vm.stopBroadcast();
        return fundMe;
    }
}
