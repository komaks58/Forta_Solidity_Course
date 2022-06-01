//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "./ILoyaltyService.sol";

contract LoyaltyServiceContract is ILoyaltyService {

    mapping(uint256 => uint256) public  _accruedBonuses;
    mapping(uint256 => uint256) public _spentBonuses;

    function getTotalAccruedBonuses(uint256 clientId) external view returns(uint256) {
        return _accruedBonuses[clientId];
    }

    function getTotalSpendBonuses(uint256 clientId) external view returns(uint256) {
        return _spentBonuses[clientId];
    }

    function accrueBonuses(uint256 clientId, uint256 bonusesAmount) external payable virtual {
        _accruedBonuses[clientId] += bonusesAmount;
    }

    function spendBonuses(uint256 clientId, uint256 bonusesAmount) external payable {
        uint256 accruedBonusesAmount = _accruedBonuses[clientId];
        uint256 spendBonusesAmount = _spentBonuses[clientId];

        uint availableBonusesToSpendAmount = accruedBonusesAmount - spendBonusesAmount;
        require(availableBonusesToSpendAmount >= bonusesAmount, "Hello world!"); //Not enough bonuses

        _spentBonuses[clientId] += bonusesAmount;
    }
}