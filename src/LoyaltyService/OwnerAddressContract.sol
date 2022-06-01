//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
contract OwnerAddressContract {
    address private _ownerAddress = msg.sender;

    constructor(){
        _ownerAddress = msg.sender;
    }

    function getOwnerAddressFromVariable() external view returns(address){
        return _ownerAddress;
    }
    
    function getOwnerAddressFromFunction() external view returns(address){
        // Не нашел функцию, которая бы возвращала адрес владельца
        return _ownerAddress;
    }
}