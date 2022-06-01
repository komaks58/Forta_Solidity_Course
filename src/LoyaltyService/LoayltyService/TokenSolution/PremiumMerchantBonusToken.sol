//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "./MerchantBonusToken.sol";

contract PremiumMerchantBonusToken is MerchantBonusToken {
    
    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) 
        MerchantBonusToken(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol) {          
        }

    function getBonusMultiplier() internal pure override returns (uint) {
        return 2;
    }
}