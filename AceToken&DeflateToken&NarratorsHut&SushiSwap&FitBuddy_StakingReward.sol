// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;



/////**{AceToken.sol}**/////

// File: contracts\open-zeppelin-contracts\SafeMath.sol

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}


// File: contracts\open-zeppelin-contracts\Context.sol

abstract contract Context {

    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this;
        return msg.data;
    }

}


// File: contracts\open-zeppelin-contracts\IBEP20.sol

interface IBEP20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);

    function decimals() external view returns(uint8);

    function symbol() external view returns(string memory);

    function name() external view returns(string memory);

    function getOwner() external view returns(address);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address _owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Factory.sol

interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns(address pair);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Router01.sol

interface IUniswapV2Router01 {

    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns(uint256 amountToken, uint256 amountETH, uint256 liquidity);

}


// File: contracts\open-zeppelin-contracts\IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}


// File: contracts\open-zeppelin-contracts\PancakePair.sol

interface PancakePair {

    function sync() external;

}


// File: contracts\open-zeppelin-contracts\Acetylene.sol

contract Acetylene is Context, IBEP20 {

    using SafeMath for uint256;

    address public pancakePair;
    address public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public pancakeRouter;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isPair;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint256 => mapping(address => bool)) private pair_timeStamp_address_voted;
    mapping(uint256 => mapping(address => uint256)) private pair_value_to_weight;
    mapping(address => mapping(uint256 => uint256)) public balanceSubmittedForVoting;
    mapping(uint256 => mapping(address => bool)) private timeStamp_address_voted;
    mapping(uint256 => mapping(uint256 => uint256)) private value_to_weight;

    string private _symbol = "ACE";
    string private _name = "Acetylene";

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 21000000 * 10 ** 18;
    uint256 public votingThreshold = (_totalSupply * 5) / 1000;
    uint256 public liquidityPercentage = 5;
    uint256 public lastPairInteraction;
    uint256 public numberOfHoursToSleep = 48;
    uint256 private _deployedAt;
    uint256 multiplier = 999 ** 8;
    uint256 divider = 1000 ** 8;

    event SleepTimerTimestamp(uint256 indexed _timestamp);
    event pairVoteTimestamp(uint256 indexed _timestamp);

    constructor() {
        _balances[msg.sender] = _totalSupply;
        IUniswapV2Router02 _pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        pancakePair = IUniswapV2Factory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        lastPairInteraction = block.timestamp;
        _isPair[pancakePair] = true;
        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        _deployedAt = block.timestamp;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external pure override returns(address) {
        return address(0);
    }

    function decimals() external view override returns(uint8) {
        return _decimals;
    }

    function symbol() external view override returns(string memory) {
        return _symbol;
    }

    function name() external view override returns(string memory) {
        return _name;
    }

    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256 _currentBalance) {
        return _balances[account];
    }

    function _updatedPairBalance(uint256 oldBalance) private returns(uint256) {
        uint256 balanceBefore = oldBalance;
        uint256 timePassed = block.timestamp - lastPairInteraction;
        uint256 power = (timePassed).div(3600); //3600: num of secs in 1 hour
        power = power <= numberOfHoursToSleep ? power : numberOfHoursToSleep;
        lastPairInteraction = power > 0 ? block.timestamp : lastPairInteraction;
        while (power > 8) {
            oldBalance = (oldBalance.mul(multiplier)).div(divider);
            power -= 8;
        }
        oldBalance = (oldBalance.mul(999 ** power)).div(1000 ** power);
        uint256 _toBurn = balanceBefore.sub(oldBalance);
        if (_toBurn > 0) {
            _balances[DEAD_ADDRESS] += _toBurn;
            emit Transfer(pancakePair, DEAD_ADDRESS, _toBurn);
        }
        return oldBalance;
    }

    function transfer(address recipient, uint256 amount) external override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        _balances[pancakePair] = _balances[pancakePair].add(tLiquidity);
        emit Transfer(sender, pancakePair, tLiquidity);
    }

    function claimVotingBalance(uint256 _timestamp, uint256 amount) external {
        require(amount > 0, "amount should be > 0");
        require(balanceSubmittedForVoting[msg.sender][_timestamp] >= amount, "requested amount more than voted amount");
        require(block.timestamp - _timestamp > 3600, "can only withdraw after round end");
        _balances[msg.sender] = _balances[msg.sender] + amount;
        balanceSubmittedForVoting[msg.sender][_timestamp] = balanceSubmittedForVoting[msg.sender][_timestamp].sub(amount);
        _balances[address(this)] = _balances[address(this)].sub(amount);
        require(_balances[msg.sender] <= getMaximumBalance(), "Balance exceeds threshold");
        emit Transfer(address(this), msg.sender, amount);
    }

    function voteForSleepTimer(uint256 timestamp, uint256 _value) external returns(uint256) {
        require(block.timestamp != timestamp, "sorry no bots");
        require(!timeStamp_address_voted[timestamp][msg.sender] || timestamp == 0, "Already voted!");
        require(_balances[msg.sender] >= votingThreshold, "non enough balance to vote");
        require(_value != numberOfHoursToSleep, "can't vote for same existing value");
        require(timestamp == 0 || (block.timestamp).sub(timestamp) <= 3600, "voting session closed");
        uint256 _timestamp = timestamp == 0 ? block.timestamp : timestamp;
        timeStamp_address_voted[_timestamp][msg.sender] = true;
        value_to_weight[_timestamp][_value] = value_to_weight[_timestamp][_value] + 1;
        _balances[msg.sender] = _balances[msg.sender] - votingThreshold;
        balanceSubmittedForVoting[msg.sender][timestamp] = balanceSubmittedForVoting[msg.sender][timestamp] + votingThreshold;
        _balances[address(this)] = _balances[address(this)] + votingThreshold;
        emit Transfer(msg.sender, address(this), votingThreshold);
        if (value_to_weight[_timestamp][_value] > 4) {
            numberOfHoursToSleep = _value;
            return 0;
        }
        emit SleepTimerTimestamp(_timestamp);
        return _timestamp;
    }

    function voteForPair(uint256 timestamp, address _value) external returns(uint256) {
        require(block.timestamp != timestamp, "sorry no bots");
        require(!pair_timeStamp_address_voted[timestamp][msg.sender] || timestamp == 0, "Already voted!");
        require(_balances[msg.sender] >= votingThreshold, "non enough balance to vote");
        require(!_isPair[_value], "address already declared as pair");
        require(timestamp == 0 || (block.timestamp).sub(timestamp) <= 3600, "voting session closed");
        uint256 _timestamp = timestamp == 0 ? block.timestamp : timestamp;
        pair_timeStamp_address_voted[_timestamp][msg.sender] = true;
        pair_value_to_weight[_timestamp][_value] = pair_value_to_weight[_timestamp][_value] + 1;
        _balances[msg.sender] = _balances[msg.sender] - votingThreshold;
        balanceSubmittedForVoting[msg.sender][timestamp] = balanceSubmittedForVoting[msg.sender][timestamp] + votingThreshold;
        _balances[address(this)] = _balances[address(this)] + votingThreshold;
        emit Transfer(msg.sender, address(this), votingThreshold);
        if (pair_value_to_weight[_timestamp][_value] > 4) {
            _isPair[_value] = true;
            return 0;
        }
        emit pairVoteTimestamp(_timestamp);
        return _timestamp;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        uint256 tLiquidity;
        if (sender == pancakePair || recipient == pancakePair) {
            tLiquidity = amount.mul(liquidityPercentage).div(100);
        }
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount.sub(tLiquidity));
        require(_isPair[recipient] || _balances[recipient] <= getMaximumBalance(), "Balance exceeds threshold");
        _takeLiquidity(sender, tLiquidity);
        emit Transfer(sender, recipient, amount.sub(tLiquidity));
    }

    function getMaximumBalance() public view returns(uint256) {
        if (block.timestamp - _deployedAt >= 1209600) return _totalSupply;
        if (block.timestamp - _deployedAt >= 604800) return (_totalSupply * 15) / 1000;
        else return _totalSupply / 100;
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function updatePrice() external {
        require(block.timestamp - lastPairInteraction >= 3600, "One execution per hour");
        uint256 _pancakeBalance = _balances[pancakePair];
        _balances[pancakePair] = _updatedPairBalance(_pancakeBalance);
        PancakePair(pancakePair).sync();
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

}



/////**{DeflateToken.sol}**/////

// import {SafeMath.sol && Context.sol && IUniswapV2Factory.sol && IUniswapV2Router01.sol && IUniswapV2Router02.sol}


// File: contracts\open-zeppelin-contracts\Address.sol

library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    // function isContract(address account) internal view returns (bool) {
    //     // This method relies in extcodesize, which returns 0 for contracts in
    //     // construction, since the code is only stored at the end of the
    //     // constructor execution.
    //     uint256 size;
    //     // solhint-disable-next-line no-inline-assembly
    //     assembly { size := extcodesize(account) }
    //     return size > 0;
    // }
    function isContract(address account) internal view returns(bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call {
            value: amount
        }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns(bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns(bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call {
            value: weiValue
        }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

}


// File: contracts\open-zeppelin-contracts\IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns(bool);

}


// File: contracts\open-zeppelin-contracts\Ownable.sol

contract Ownable is Context {

    address private _owner;
    address private _previousOwner;

    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns(uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

}


// File: contracts\open-zeppelin-contracts\Name.sol

contract Name is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;
    address public charityWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public uniswapV2Pair;

    string private _name = "Name COIN";
    string private _symbol = "Name";

    uint8 private _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 42000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 3;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _burnFee = 3;
    uint256 private _previousBurnFee = _burnFee;
    uint256 public _charityFee = 5;
    uint256 private _previouscharityFee = _charityFee;
    uint256 private numTokensSellToAddToLiquidity = 8000 * 10 ** 18;

    IUniswapV2Router02 public uniswapV2Router;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns(uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns(uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns(bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns(uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, "We can not exclude Pancake router.");
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns(uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns(uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_taxFee).div(10 ** 2);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(_liquidityFee).div(10 ** 2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _charityFee == 0 && _burnFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previouscharityFee = _charityFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
        _charityFee = _previouscharityFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH {
            value: ethAmount
        }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            removeAllFee();
        }
        //Calculate burn amount and charity amount
        uint256 burnAmt = amount.mul(_burnFee).div(100);
        uint256 charityAmt = amount.mul(_charityFee).div(100);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, (amount.sub(burnAmt).sub(charityAmt)));
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, (amount.sub(burnAmt).sub(charityAmt)));
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(charityAmt)));
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, (amount.sub(burnAmt).sub(charityAmt)));
        } else {
            _transferStandard(sender, recipient, (amount.sub(burnAmt).sub(charityAmt)));
        }
        //Temporarily remove fees to transfer to burn address and charity wallet
        _taxFee = 0;
        _liquidityFee = 0;
        _transferStandard(sender, address(0), burnAmt);
        _transferStandard(sender, charityWallet, charityAmt);
        //Restore tax and liquidity fees
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setcharityWallet(address newWallet) external onlyOwner() {
        charityWallet = newWallet;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setChartityFeePercent(uint256 charityFee) external onlyOwner() {
        _charityFee = charityFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    //New Pancakeswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

}



/////**{NarratorsHut.sol}**/////

// import{Address.sol && IERC20.sol && Context.sol && Ownable.sol}


// File: contracts\open-zeppelin-contracts\Strings.sol

library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns(string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns(string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File: contracts\open-zeppelin-contracts\Signatures.sol

library Signatures {

    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes constant TOKEN_DATA_TYPE_DEF = "TokenData(uint32 artifactId,uint32 witchId)";

    bytes32 constant MINT_TYPEHASH = keccak256(abi.encodePacked("Mint(address minterAddress,uint256 totalCost,uint256 expiresAt,TokenData[] tokenDataArray)", TOKEN_DATA_TYPE_DEF));

    bytes32 constant TOKEN_DATA_TYPEHASH = keccak256(TOKEN_DATA_TYPE_DEF);

    function recreateMintHash(bytes32 domainSeparator, address minterAddress, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) internal pure returns(bytes32) {
        bytes32 mintHash = _hashMint(minterAddress, totalCost, expiresAt, tokenDataArray);
        return _eip712Message(domainSeparator, mintHash);
    }

    function _hashMint(address minterAddress, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) private pure returns(bytes32) {
        bytes32[] memory tokenDataHashes = new bytes32[](tokenDataArray.length);
        for (uint256 i; i < tokenDataArray.length;) {
            tokenDataHashes[i] = _hashTokenData(tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }
        return keccak256(abi.encode(MINT_TYPEHASH, minterAddress, totalCost, expiresAt, keccak256(abi.encodePacked(tokenDataHashes))));
    }

    function _hashTokenData(TokenData calldata tokenData) private pure returns(bytes32) {
        return keccak256(abi.encode(TOKEN_DATA_TYPEHASH, tokenData.artifactId, tokenData.witchId));
    }

    function _eip712Message(bytes32 domainSeparator, bytes32 dataHash) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(uint16(0x1901), domainSeparator, dataHash));
    }

}


// File: contracts\open-zeppelin-contracts\SignatureChecker.sol

library SignatureChecker {

    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns(bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }

}


// File: contracts\open-zeppelin-contracts\ECDSA.sol

library ECDSA {

    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns(address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns(address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address, RecoverError) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }
        return (signer, RecoverError.NoError);
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns(address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

}


// File: contracts\open-zeppelin-contracts\MerkleProof.sol

library MerkleProof {

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns(bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

}


// File: contracts\open-zeppelin-contracts\IERC165.sol

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns(bool);

}


// File: contracts\open-zeppelin-contracts\ERC165.sol

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}


// File: contracts\open-zeppelin-contracts\IERC2981.sol

interface IERC2981 is IERC165 {

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns(address receiver, uint256 royaltyAmount);

}


// File: contracts\open-zeppelin-contracts\IERC721.sol

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns(uint256 balance);

    function ownerOf(uint256 tokenId) external view returns(address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns(address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns(bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}


// File: contracts\open-zeppelin-contracts\IERC721Metadata.sol

interface IERC721Metadata is IERC721 {

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function tokenURI(uint256 tokenId) external view returns(string memory);

}


// File: contracts\open-zeppelin-contracts\ERC721.sol

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;

    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns(uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns(string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns(bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File: contracts\open-zeppelin-contracts\ERC721Hut.sol

struct TokenDataStorage {
    uint48 artifactId;
    uint48 witchId;
    address owner; // 160 bits
}

contract ERC721Hut is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;

    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => TokenDataStorage) private _tokenDataStorage;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns(uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns(address) {
        address owner = _tokenDataStorage[tokenId].owner;
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns(string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Hut.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns(address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns(bool) {
        return _tokenDataStorage[tokenId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
        address owner = ERC721Hut.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId) internal virtual {
        _safeMint(to, tokenId, artifactId, witchId, "");
    }

    function _safeMint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId, bytes memory _data) internal virtual {
        _mint(to, tokenId, artifactId, witchId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId, uint48 artifactId, uint48 witchId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _tokenDataStorage[tokenId].owner = to;
        _tokenDataStorage[tokenId].artifactId = artifactId;
        _tokenDataStorage[tokenId].witchId = witchId;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Hut.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _tokenDataStorage[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Hut.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokenDataStorage[tokenId].owner = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Hut.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _getDataForToken(uint256 tokenId) internal view returns(uint48, uint48) {
        uint48 artifactId = _tokenDataStorage[tokenId].artifactId;
        uint48 witchId = _tokenDataStorage[tokenId].witchId;
        return (artifactId, witchId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

}


// File: contracts\open-zeppelin-contracts\INarratorsHut.sol

struct MintInput {
    uint256 totalCost;
    uint256 expiresAt;
    TokenData[] tokenDataArray;
    bytes mintSignature;
}

struct TokenData {
    uint48 witchId;
    uint48 artifactId;
}

interface INarratorsHut {

    function mint(MintInput calldata mintInput) external payable;

    function getArtifactForToken(uint256 tokenId) external view returns(ArtifactManifestation memory);

    function getTokenIdForArtifact(address addr, uint48 artifactId, uint48 witchId) external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function setIsSaleActive(bool _status) external;

    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive) external;

    function setMetadataContractAddress(address _metadataContractAddress) external;

    function setNarratorAddress(address _narratorAddress) external;

    function setBaseURI(string calldata _baseURI) external;

    function withdraw() external;

    function withdrawToken(IERC20 token) external;

}


// File: contracts\open-zeppelin-contracts\INarratorsHutMetadata.sol

struct CraftArtifactData {
    uint256 id;
    string name;
    string description;
    string[] attunements;
}

struct Artifact {
    bool mintable;
    string name;
    string description;
    string[] attunements;
}

struct ArtifactManifestation {
    string name;
    string description;
    uint256 witchId;
    uint256 artifactId;
    AttunementManifestation[] attunements;
}

struct AttunementManifestation {
    string name;
    int256 value;
}

interface INarratorsHutMetadata {

    function getArtifactForToken(uint256 artifactId, uint256 tokenId, uint256 witchId) external view returns(ArtifactManifestation memory);

    function canMintArtifact(uint256 artifactId) external view returns(bool);

    function craftArtifact(CraftArtifactData calldata data) external;

    function getArtifact(uint256 artifactId) external view returns(Artifact memory);

    function lockArtifacts(uint256[] calldata artifactIds) external;

}


// File: contracts\open-zeppelin-contracts\NarratorsHut.sol

contract NarratorsHut is INarratorsHut, ERC721Hut, IERC2981, Ownable {

    uint256 private tokenCounter;

    string private baseURI;

    bool public isSaleActive = false;

    bool private isOpenSeaConduitActive = true;

    address public metadataContractAddress;

    address public narratorAddress;

    bytes32 private immutable domainSeparator;

    mapping(bytes32 => uint256) private _tokenIdsByMintKey;

    constructor(address _metadataContractAddress, address _narratorAddress, string memory _baseURI) ERC721Hut("The Narrator's Hut", "HUT") {
        domainSeparator = keccak256(abi.encode(Signatures.DOMAIN_TYPEHASH, keccak256(bytes("MintToken")), keccak256(bytes("1")), block.chainid, address(this)));
        metadataContractAddress = _metadataContractAddress;
        narratorAddress = _narratorAddress;
        baseURI = _baseURI;
    }

    modifier saleIsActive() {
        if (!isSaleActive) revert SaleIsNotActive();
        _;
    }

    modifier isCorrectPayment(uint256 totalCost) {
        if (totalCost != msg.value) revert IncorrectPaymentReceived();
        _;
    }

    modifier isValidMintSignature(bytes calldata mintSignature, uint256 totalCost, uint256 expiresAt, TokenData[] calldata tokenDataArray) {
        if (narratorAddress == address(0)) {
            revert InvalidNarratorAddress();
        }
        if (block.timestamp >= expiresAt) {
            revert MintSignatureHasExpired();
        }

        bytes32 recreatedHash = Signatures.recreateMintHash(domainSeparator, msg.sender, totalCost, expiresAt, tokenDataArray);

        if (!SignatureChecker.isValidSignatureNow(narratorAddress, recreatedHash, mintSignature)) {
            revert InvalidMintSignature();
        }
        _;
    }

    modifier canMintArtifact(TokenData calldata tokenData) {
        if (getTokenIdForArtifact(msg.sender, tokenData.artifactId, tokenData.witchId) > 0) {
            revert ArtifactCapReached();
        }

        INarratorsHutMetadata metadataContract = INarratorsHutMetadata(metadataContractAddress);
        if (!metadataContract.canMintArtifact(tokenData.artifactId)) {
            revert ArtifactIsNotMintable();
        }
        _;
    }

    function mint(MintInput calldata mintInput) external payable saleIsActive isValidMintSignature(mintInput.mintSignature, mintInput.totalCost, mintInput.expiresAt, mintInput.tokenDataArray) isCorrectPayment(mintInput.totalCost) {
        for (uint256 i; i < mintInput.tokenDataArray.length;) {
            mintArtifact(mintInput.tokenDataArray[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getArtifactForToken(uint256 tokenId) external view returns(ArtifactManifestation memory) {
        (uint256 artifactId, uint256 witchId) = _getDataForToken(tokenId);
        return INarratorsHutMetadata(metadataContractAddress).getArtifactForToken(artifactId, tokenId, witchId);
    }

    function getTokenIdForArtifact(address addr, uint48 artifactId, uint48 witchId) public view returns(uint256) {
        bytes32 mintKey = getMintKey(addr, artifactId, witchId);
        return _tokenIdsByMintKey[mintKey];
    }

    function getBaseURI() external view returns(string memory) {
        return baseURI;
    }

    function totalSupply() external view returns(uint256) {
        return tokenCounter;
    }

    function setIsSaleActive(bool _status) external onlyOwner {
        isSaleActive = _status;
    }

    function setIsOpenSeaConduitActive(bool _isOpenSeaConduitActive) external onlyOwner {
        isOpenSeaConduitActive = _isOpenSeaConduitActive;
    }

    function setMetadataContractAddress(address _metadataContractAddress) external onlyOwner {
        metadataContractAddress = _metadataContractAddress;
    }

    function setNarratorAddress(address _narratorAddress) external onlyOwner {
        narratorAddress = _narratorAddress;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert PaymentBalanceZero();
        }
        (bool success, bytes memory result) = owner().call {
            value: balance
        }("");
        if (!success) {
            revert PaymentUnsuccessful(result);
        }
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert PaymentBalanceZero();
        }
        token.transfer(msg.sender, balance);
    }

    function nextTokenId() private returns(uint256) {
        unchecked {
            ++tokenCounter;
        }
        return tokenCounter;
    }

    function getMintKey(address addr, uint48 artifactId, uint48 witchId) private pure returns(bytes32) {
        if (witchId != 0) {
            return bytes32(abi.encodePacked(witchId, artifactId));
        } else {
            return bytes32(abi.encodePacked(addr, artifactId));
        }
    }

    function mintArtifact(TokenData calldata tokenData) private canMintArtifact(tokenData) {
        uint256 tokenId = nextTokenId();
        bytes32 mintKey = getMintKey(msg.sender, tokenData.artifactId, tokenData.witchId);
        _tokenIdsByMintKey[mintKey] = tokenId;
        _mint(msg.sender, tokenId, tokenData.artifactId, tokenData.witchId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Hut, IERC165) returns(bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator) public view override returns(bool) {
        if (isOpenSeaConduitActive && operator == 0x1E0049783F008A0085193E00003D00cd54003c71) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        if (!_exists(tokenId)) revert TokenURIQueryForNonexistentToken();
        string memory url = string.concat(baseURI, "/", Strings.toString(tokenId));
        return url;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns(address receiver, uint256 royaltyAmount) {
        if (!_exists(tokenId)) revert RoyaltiesQueryForNonexistentToken();
        return (owner(), (salePrice * 5) / 100);
    }

    error SaleIsNotActive();
    error IncorrectPaymentReceived();
    error ArtifactCapReached();
    error ArtifactIsNotMintable();
    error RoyaltiesQueryForNonexistentToken();
    error TokenURIQueryForNonexistentToken();
    error MintSignatureHasExpired();
    error InvalidNarratorAddress();
    error InvalidMintSignature();
    error PaymentBalanceZero();
    error PaymentUnsuccessful(bytes result);

}


// File: contracts\open-zeppelin-contracts\IERC721Receiver.sol

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);

}


// File: contracts\open-zeppelin-contracts\IERC1271.sol

interface IERC1271 {

    function isValidSignature(bytes32 hash, bytes memory signature) external view returns(bytes4 magicValue);

}



/////**{SushiSwap.sol}**/////

// File: contracts\open-zeppelin-contracts\SafeMathSushiswap.sol

library SafeMathSushiswap {

    function add(uint x, uint y) internal pure returns(uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns(uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns(uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

}


// File: contracts\open-zeppelin-contracts\SushiswapV3Library.sol

library SushiswapV3Library {

    using SafeMathSushiswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {
        require(tokenA != tokenB, "SushiswapV3Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SushiswapV3Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns(address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
        )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns(uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = ISushiswapV3Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns(uint amountB) {
        require(amountA > 0, "SushiswapV3Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SushiswapV3Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns(uint amountOut) {
        require(amountIn > 0, "SushiswapV3Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SushiswapV3Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns(uint amountIn) {
        require(amountOut > 0, "SushiswapV3Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SushiswapV3Library: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns(uint[] memory amounts) {
        require(path.length >= 2, "SushiswapV3Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns(uint[] memory amounts) {
        require(path.length >= 2, "SushiswapV3Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

}


// File: contracts\open-zeppelin-contracts\TransferHelper.sol

// helper mFTMods for interacting with ERC20 tokens and sending FTM that do not consistently return true/false
library TransferHelper {

    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferFTM(address to, uint value) internal {
        (bool success, ) = to.call {
            value: value
        }(new bytes(0));
        require(success, "TransferHelper: FTM_TRANSFER_FAILED");
    }

}


// File: contracts\open-zeppelin-contracts\ISushiswapV3Pair.sol

interface ISushiswapV3Pair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function name() external pure returns(string memory);

    function symbol() external pure returns(string memory);

    function decimals() external pure returns(uint8);

    function totalSupply() external view returns(uint);

    function balanceOf(address owner) external view returns(uint);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint value) external returns(bool);

    function transfer(address to, uint value) external returns(bool);

    function transferFrom(address from, address to, uint value) external returns(bool);

    function DOMAIN_SEPARATOR() external view returns(bytes32);

    function PERMIT_TYPEHASH() external pure returns(bytes32);

    function nonces(address owner) external view returns(uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns(uint);

    function factory() external view returns(address);

    function token0() external view returns(address);

    function token1() external view returns(address);

    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns(uint);

    function price1CumulativeLast() external view returns(uint);

    function kLast() external view returns(uint);

    function mint(address to) external returns(uint liquidity);

    function burn(address to) external returns(uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

}


// File: contracts\open-zeppelin-contracts\ISushiswapV3Router01.sol

interface ISushiswapV3Router01 {

    function factory() external view returns(address);

    function WFTM() external view returns(address);

    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns(uint amountA, uint amountB, uint liquidity);

    function addLiquidityFTM(address token, uint amountTokenDesired, uint amountTokenMin, uint amountFTMMin, address to, uint deadline) external payable returns(uint amountToken, uint amountFTM, uint liquidity);

    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns(uint amountA, uint amountB);

    function removeLiquidityFTM(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline) external returns(uint amountToken, uint amountFTM);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint amountA, uint amountB);

    function removeLiquidityFTMWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint amountToken, uint amountFTM);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns(uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns(uint[] memory amounts);

    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns(uint[] memory amounts);

    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns(uint[] memory amounts);

    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns(uint[] memory amounts);

    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns(uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);

}


// File: contracts\open-zeppelin-contracts\ISushiswapV3Router02.sol

interface ISushiswapV3Router02 is ISushiswapV3Router01 {

    function removeLiquidityFTMSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline) external returns(uint amountFTM);

    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint amountFTM);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

    function swapExactFTMForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;

    function swapExactTokensForFTMSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

}


// File: contracts\open-zeppelin-contracts\ISushiswapV3Factory.sol

interface ISushiswapV3Factory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns(address);

    function feeToSetter() external view returns(address);

    function migrator() external view returns(address);

    function getPair(address tokenA, address tokenB) external view returns(address pair);

    function allPairs(uint) external view returns(address pair);

    function allPairsLength() external view returns(uint);

    function createPair(address tokenA, address tokenB) external returns(address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;

}


// File: contracts\open-zeppelin-contracts\IERC20Sushi.sol

interface IERC20Sushi {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external view returns(uint8);

    function totalSupply() external view returns(uint);

    function balanceOf(address owner) external view returns(uint);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint value) external returns(bool);

    function transfer(address to, uint value) external returns(bool);

    function transferFrom(address from, address to, uint value) external returns(bool);

    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns(bool);

}


// File: contracts\open-zeppelin-contracts\IWFTM.sol

interface IWFTM {

    function deposit() external payable;

    function transfer(address to, uint value) external returns(bool);

    function withdraw(uint) external;

}


// File: contracts\open-zeppelin-contracts\SushiswapV3PermitRouter02.sol

contract SushiswapV3PermitRouter02 {

    using SafeMathSushiswap for uint;

    address public immutable factory;
    address public immutable WFTM;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SushiswapV3Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WFTM) {
        factory = _factory;
        WFTM = _WFTM;
    }

    receive() external payable {
        assert(msg.sender == WFTM); // only accept FTM via fallback from the WFTM contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin) internal virtual returns(uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISushiswapV3Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISushiswapV3Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SushiswapV3Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SushiswapV3Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "SushiswapV3Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SushiswapV3Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "SushiswapV3Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidityWithPermit(address from, address[2] calldata tokens, uint[2] calldata desired, uint[2] calldata mins, address to, uint deadline, uint8[2] calldata v, bytes32[2] calldata r, bytes32[2] calldata s) external virtual ensure(deadline) returns(uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokens[0], tokens[1], desired[0], desired[1], mins[0], mins[1]);
        address pair = SushiswapV3Library.pairFor(factory, tokens[0], tokens[1]);
        IERC20Sushi(tokens[0]).transferWithPermit(from, pair, amountA, deadline, v[0], r[0], s[0]);
        IERC20Sushi(tokens[1]).transferWithPermit(from, pair, amountB, deadline, v[1], r[1], s[1]);
        liquidity = ISushiswapV3Pair(pair).mint(to);
    }

    function addLiquidityFTMWithPermit(address from, address token, uint amountTokenDesired, uint[2] calldata mins, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual payable ensure(deadline) returns(uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(token, WFTM, amountTokenDesired, msg.value, mins[0], mins[1]);
        address pair = SushiswapV3Library.pairFor(factory, token, WFTM);
        IERC20Sushi(token).transferWithPermit(from, pair, amountA, deadline, v, r, s);
        IWFTM(WFTM).deposit {
            value: amountB
        }();
        assert(IWFTM(WFTM).transfer(pair, amountB));
        liquidity = ISushiswapV3Pair(pair).mint(to);
        // refund dust FTM, if any
        if (msg.value > amountB) TransferHelper.safeTransferFTM(msg.sender, msg.value - mins[1]);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) public virtual ensure(deadline) returns(uint amountA, uint amountB) {
        address pair = SushiswapV3Library.pairFor(factory, tokenA, tokenB);
        ISushiswapV3Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISushiswapV3Pair(pair).burn(to);
        (address token0, ) = SushiswapV3Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "SushiswapV3Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SushiswapV3Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityFTM(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline) public virtual ensure(deadline) returns(uint amountToken, uint amountFTM) {
        (amountToken, amountFTM) = removeLiquidity(token, WFTM, liquidity, amountTokenMin, amountFTMMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWFTM(WFTM).withdraw(amountFTM);
        TransferHelper.safeTransferFTM(to, amountFTM);
    }

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external virtual returns(uint amountA, uint amountB) {
        address pair = SushiswapV3Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint).max : liquidity;
        ISushiswapV3Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityFTMWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountFTMMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external virtual returns(uint amountToken, uint amountFTM) {
        address pair = SushiswapV3Library.pairFor(factory, token, WFTM);
        uint value = approveMax ? type(uint).max : liquidity;
        ISushiswapV3Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountFTM) = removeLiquidityFTM(token, liquidity, amountTokenMin, amountFTMMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = SushiswapV3Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SushiswapV3Library.pairFor(factory, output, path[i + 2]) : _to;
            ISushiswapV3Pair(SushiswapV3Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensWithPermit(address from, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual ensure(deadline) returns(uint[] memory amounts) {
        amounts = SushiswapV3Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SushiswapV3Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20Sushi(path[0]).transferWithPermit(from, SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0], deadline, v, r, s);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokensWithPermit(address from, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual ensure(deadline) returns(uint[] memory amounts) {
        amounts = SushiswapV3Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "SushiswapV3Router: EXCESSIVE_INPUT_AMOUNT");
        IERC20Sushi(path[0]).transferWithPermit(from, SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0], deadline, v, r, s);
        _swap(amounts, path, to);
    }

    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external virtual payable ensure(deadline) returns(uint[] memory amounts) {
        require(path[0] == WFTM, "SushiswapV3Router: INVALID_PATH");
        amounts = SushiswapV3Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SushiswapV3Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IWFTM(WFTM).deposit {
            value: amounts[0]
        }();
        assert(IWFTM(WFTM).transfer(SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactFTMWithPermit(address from, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual ensure(deadline) returns(uint[] memory amounts) {
        require(path[path.length - 1] == WFTM, "SushiswapV3Router: INVALID_PATH");
        amounts = SushiswapV3Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "SushiswapV3Router: EXCESSIVE_INPUT_AMOUNT");
        IERC20Sushi(path[0]).transferWithPermit(from, SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0], deadline, v, r, s);
        _swap(amounts, path, address(this));
        IWFTM(WFTM).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferFTM(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForFTM(address from, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual ensure(deadline) returns(uint[] memory amounts) {
        require(path[path.length - 1] == WFTM, "SushiswapV3Router: INVALID_PATH");
        amounts = SushiswapV3Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SushiswapV3Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20Sushi(path[0]).transferWithPermit(from, SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0], deadline, v, r, s);
        _swap(amounts, path, address(this));
        IWFTM(WFTM).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferFTM(to, amounts[amounts.length - 1]);
    }

    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external virtual payable ensure(deadline) returns(uint[] memory amounts) {
        require(path[0] == WFTM, "SushiswapV3Router: INVALID_PATH");
        amounts = SushiswapV3Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "SushiswapV3Router: EXCESSIVE_INPUT_AMOUNT");
        IWFTM(WFTM).deposit {
            value: amounts[0]
        }();
        assert(IWFTM(WFTM).transfer(SushiswapV3Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust FTM, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferFTM(msg.sender, msg.value - amounts[0]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual returns(uint amountB) {
        return SushiswapV3Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure virtual returns(uint amountOut) {
        return SushiswapV3Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure virtual returns(uint amountIn) {
        return SushiswapV3Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view virtual returns(uint[] memory amounts) {
        return SushiswapV3Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view virtual returns(uint[] memory amounts) {
        return SushiswapV3Library.getAmountsIn(factory, amountOut, path);
    }

}



/////**{FitBuddy_StakingReward.sol}**/////

// import {Address.sol && SafeMath.sol && IERC20.sol}


// File: contracts\open-zeppelin-contracts\Math.sol

library Math {

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns(uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

}


// File: contracts\open-zeppelin-contracts\SafeERC20.sol

library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

}


// File: contracts\open-zeppelin-contracts\Owned.sol

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

}


// File: contracts\open-zeppelin-contracts\Pausable.sol

abstract contract Pausable is Owned {

    uint public lastPauseTime;

    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }
        // Set our paused state.
        paused = _paused;
        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }
        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

}


// File: contracts\open-zeppelin-contracts\RewardsDistributionRecipient.sol

abstract contract RewardsDistributionRecipient is Owned {

    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function notifyRewardAmount(uint256 reward) virtual external;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }

}


// File: contracts\open-zeppelin-contracts\ReentrancyGuard.sol

abstract contract ReentrancyGuard {

    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    constructor() {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */

}


// File: contracts\open-zeppelin-contracts\IStakingRewards.sol

interface IStakingRewards {

    // Views

    function lastTimeRewardApplicable() external view returns(uint256);

    function rewardPerToken() external view returns(uint256);

    function earned(address account) external view returns(uint256);

    function getRewardForDuration() external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

}


// File: contracts\open-zeppelin-contracts\StakingRewards.sol

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Pausable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 private _totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    ) Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external override view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns(uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public override view returns(uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public override view returns(uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    function earned(address account) public override view returns(uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external override view returns(uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish, "Previous rewards period must be complete before changing the duration for the new period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

}
