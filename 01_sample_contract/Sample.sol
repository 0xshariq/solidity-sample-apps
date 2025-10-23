// SPDX-License-Identifier: MIT
//
// https://cryptomarketpool.com/simple-contract

pragma solidity ^0.8.0; // specify the version of Solidity

// sample contract
contract MyContract {
    string private name; // private variable to store name
    uint256 private age; // private variable to store age

    // function to set name
    function setName(string memory _name) public {
        name = _name;
    }

    // function to get name
    function getName() public view returns (string memory) {
        return name;
    }

    // function to set age
    function setAge(uint256 _age) public {
        age = _age;
    }

    // function to get age
    function getAge() public view returns (uint256) {
        return age;
    }
}