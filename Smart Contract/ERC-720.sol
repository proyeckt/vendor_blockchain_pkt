// SPDX-License-Identifier: MIT

// https://ethereum.org/en/developers/docs/standards/tokens/erc-20

pragma solidity ^0.8.0;

//Standart give a template, we need to create an abstract contract to implement functions
abstract contract ERC20_STD {

  function name() public view virtual returns (string memory);
  function symbol() public view virtual returns (string memory);
  function decimals() public view virtual returns (uint8);
  function totalSupply() public view virtual returns (uint256);
  function minter() public view virtual returns (address);

  function balanceOf(address _owner) public view virtual  returns (uint256 balance);
  function transfer(address _to, uint256 _value) public virtual returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
  function approve(address _spender, uint256 _value) public virtual returns (bool success);
  function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);



}

contract Ownership {
  address public contractOwner;
  address public newOwner;

  event TransferOwnership(address indexed _from,address indexed _to);

  constructor(){
    contractOwner = msg.sender;
  }

  function changeOwner(address _to) public {
    require(msg.sender == contractOwner, "Only Owner.");
    newOwner = _to;
  }

  function acceptOwner() public {
    require(msg.sender == newOwner, 'Only assigned new owner.');
    emit TransferOwnership(contractOwner,newOwner);
    contractOwner = newOwner;
    newOwner = address(0); //Reset temp variable of newOwner
  }
}

contract MyERC20 is ERC20_STD, Ownership {
  
  //These attributes could be private (?)
  string public _name; //Name of our coin
  string public _symbol; 
  uint8 public _decimals;
  uint256 public _totalSupply;

  address public _minter; //Account that is creating the token, creating the money, and distributing
  //the money by sending/transferring to other accounts.

  mapping(address => uint256) tokenBalances; //State variable to keep track of token's ownership, mapping 
  //from an address and his value (how many tokens)

  mapping(address => mapping(address => uint256)) allowed; //Keeping track the address of the owner,
  //who has designated certain address and how much/how many tokens there has been allowed to use

  constructor(address minter_){
    _name = "PROYECKT COIN";
    _symbol = "PKT";
    _decimals = 0;
    _totalSupply = 1000000;
    _minter = minter_; //It's like the finantial controller

    tokenBalances[_minter] = _totalSupply;
  }

  function name() public view override returns (string memory){
    return _name;
  }
  function symbol() public view override returns (string memory){
    return _symbol;
  }
  function decimals() public view override returns (uint8){
    return _decimals;
  }
  function totalSupply() public view override returns (uint256){
    return _totalSupply;
  }
  function minter() public view override returns (address){
    return _minter;
  }

  //How many tokens is available for each token's owner
  function balanceOf(address _owner) public view override  returns (uint256 balance){
    return tokenBalances[_owner];
  }

  function transfer(address _to, uint256 _value) public override returns (bool success){
    require(tokenBalances[msg.sender] >= _value, 'Insufficient tokens');
    tokenBalances[msg.sender] -= _value;
    tokenBalances[_to] += _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
    //Do you have the aproval to do that?
    uint256 allowedBalance = allowed[_from][msg.sender]; //Quantity of the value that is allowed to use
    //Warning with a zero-value, it's possible to allowedBalance to be zero and if value is 0 too,
    //require sentece could be pass
    require(allowedBalance >= _value,'Insufficient Limit Allowed');
    tokenBalances[_from] -= _value;
    tokenBalances[_to] += _value;

    //For me, it seems optional
    allowed[_from][msg.sender] -= _value;

    emit Transfer(_from, _to, _value);

    return true;
  }

  //To manage delegations
  function approve(address _spender, uint256 _value) public override returns (bool success){
    require(tokenBalances[msg.sender] >= _value,'Insufficient tokens');
    //Aprove is to set an aproval and the value allowed to use
    //Spender is who needs to be delegated by the aproval (owner)
    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
    return allowed[_owner][_spender];
  }
  
  //Minter can create more quantity of token, add more amount of token avaliable
  function mintToken(uint256 _amount) public {
    require(msg.sender == _minter, 'Only minter.');

    tokenBalances[_minter] += _amount;
    _totalSupply += _amount;

    emit Transfer(address(0), _minter, _amount);
  }

  //Minter can remove token of circulation, reduce quantity of token
  //If you flood the market with too many tokens, the price will go down
  //This helps to regulate supply and demand. 
  //Remove is to reduce supply, therefore increasing demand
  function burnToken(uint256 _amount) public {
    require(msg.sender == _minter, 'Only minter.');

    tokenBalances[_minter] -= _amount;
    _totalSupply -= _amount;

    emit Transfer(_minter,address(0), _amount);
  }

  //Confiscate token, maybe for inactive users on the site, or hackers who stole, etc
  function takeToken(address target, uint _amount ) public returns (bool) {
    require(msg.sender == _minter, 'Only minter.');

    uint256 targetBal = tokenBalances[target];
    if(targetBal >= _amount){
      tokenBalances[target] -= _amount;
      tokenBalances[_minter] += _amount;
      emit Transfer(target, _minter, _amount);
    }else{
      tokenBalances[_minter] += targetBal;
      tokenBalances[target] = 0;
      emit Transfer(target, _minter, targetBal);
    }

    return true;
  }

}
