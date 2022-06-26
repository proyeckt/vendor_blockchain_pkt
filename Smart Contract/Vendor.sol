// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC-720.sol';

/*
Purpose: Smart contract for a Vendor with the following functions:
- buyToken();
- sellToken();
withdrawalBalances()
*/

contract VendorPKT is Ownership {
    MyERC20 _myERC20;
    address private VOwner; //Address of the vendor owner

    uint TokensPerEther = 100; //It means that 1 Eth will buy 100 PKT tokens

    event BuyToken(address indexed buyer,uint256 _value, uint256 _tokenQty);
    event SellToken(address indexed seller,uint256 _amount, uint256 _amountEth);
    event WithdrawBalance(address indexed ,uint256 contractBal);

    constructor(address myERC20_){
        VOwner = msg.sender;
        //Instance of the contract passing the address of the smart contract deployed as argument
        _myERC20 = MyERC20 (myERC20_ ); 
    }

    function buyToken() public payable returns (bool) {
        require (msg.value >= 1 ether,'Minimum purchase is 1 ether');
        
        //Convert value to ether value
        uint256 valueInEther = msg.value / 1 ether;

        //Value in ether must be converted in how many tokens are equivalent
        uint256 tokenQty = valueInEther * TokensPerEther;
        uint256 vendorTokenBal = _myERC20.balanceOf(address(this));

        require (vendorTokenBal >= tokenQty, 'Insufficient vendor tokens');

        bool sent = _myERC20.transfer(msg.sender,tokenQty);

        require(sent,'Token purchase transfer failed');

        emit BuyToken(msg.sender, valueInEther, tokenQty);

        return true;
    }

    //To sell is required to approve spender (vendor contract address) to the value desired
    function sellToken(uint256 amount) public payable returns (bool){
        uint256 _token = amount %   TokensPerEther;
        require(_token == 0, 'Must sell in multiple of 100');

        //address(this) is the address of the contract
        uint256 limitQty = _myERC20.allowance(msg.sender,address(this));
        require(amount >= limitQty, 'Exceeded allowed quantity');

        uint256 qtyInEther = amount / TokensPerEther;
        uint vendorBal = address(this).balance / 1 ether;
        require(vendorBal >= qtyInEther,'Insufficient vendor balance');

        //Transfer to vendor
        bool success = _myERC20.transferFrom(msg.sender,address(this),amount);
        require(success,'Token sale to vendor transfer failed');

        //Get money for the sale
        (bool sent,) = msg.sender.call{value: qtyInEther * 1e18 }('');
        require(sent,'Token sale to seller transfer failed');


        emit SellToken(msg.sender,amount, qtyInEther);

        return true;
    }

    function withdrawal() public payable returns (bool){
        require(msg.sender == VOwner, 'Only vendor can withdraw');

        uint256 contractBal = address(this).balance;
        require(contractBal>0, 'Balance must be greater than zero');

        (bool sent,) = msg.sender.call{value: contractBal }('');

        require(sent,'Failed in withadrawal');

        emit WithdrawBalance(msg.sender,contractBal);

        return true;
    }
}