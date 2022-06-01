//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface ILoyaltyService{
    function getTotalAccruedBonuses(uint256 clientId) external view returns(uint256);

    function getTotalSpendBonuses(uint256 clientId) external view returns(uint256);

    function accrueBonuses(uint256 clientId, uint256 bonusesAmount) external payable;

    function spendBonuses(uint256 clientId, uint256 bonusesAmount) external payable;
}