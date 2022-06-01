//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "./LoyaltyServiceContract.sol";

contract VipLoyaltyServiceContract is LoyaltyServiceContract {

    function accrueBonuses(uint256 clientId, uint256 bonusesAmount) external payable override {
        _accruedBonuses[clientId] += bonusesAmount * 5;
    }
}