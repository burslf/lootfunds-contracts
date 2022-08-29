// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


/**
 * LockMyTokens main contract.
 * @author Yoel Zerbib
 * Date created: 16.7.22.
 * Github
**/


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LockMyTokens {

    // Balances
    mapping(ERC20 => mapping(address => uint)) ERC20Balances;

    // Locked balances
    mapping(ERC20 => mapping(address => uint)) lockedBalances;
    mapping(ERC20 => mapping(address => uint)) unboundingTime;
    
    // Native balances
    mapping(address => uint) nativeBalances;
    mapping(address => uint) nativeLockedBalances;
    mapping(address => uint) nativeUnboundingTime;

    // Events
    event TransferReceived(address _receivAddr, uint _amount);
    event TransferSent(address _from, uint _amount);

    event LockedTransferReceived(address _from, uint _amount, uint _unboundingTime);
    event LockedTransferSent(address _from, uint _amount);
    
    event NativeTransferReceived(address _receivAddr, uint _amount);
    event NativeTransferSent(address _receivAddr, uint _amount);
    
    event NativeLockedTransferReceived(address _receivAddr, uint _amount, uint _unboundingTime);
    event NativeLockedTransferSent(address _receivAddr, uint _amount);
    
    function walletBalance(ERC20 _tokenAddress, address _userAddress) public view returns (uint _available, uint _locked) {
        return (ERC20Balances[_tokenAddress][_userAddress], lockedBalances[_tokenAddress][_userAddress]);
    }

    function walletNativeBalance(address _userAddress) public view returns (uint _available, uint _locked) {
        return (nativeBalances[_userAddress], nativeLockedBalances[_userAddress]);

    }

    function unboundingDate(ERC20 _token, address _userAddress) public view returns (uint) {
        return unboundingTime[_token][_userAddress];
    }

    function lockERC20(ERC20 _token, uint256 _amount, uint256 _timestamp) public {
        uint256 erc20balance = IERC20(_token).balanceOf(msg.sender);
        require(_amount <= erc20balance, "balance is low");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        lockedBalances[_token][msg.sender] += _amount;
        unboundingTime[_token][msg.sender] = _timestamp;

        emit LockedTransferReceived(msg.sender, _amount, _timestamp);
    }

    function withdrawLockedERC20(ERC20 _token, uint _amount, address payable _destAddr) public {
        require(_amount <= lockedBalances[_token][msg.sender], "Insufficient funds");
        require(unboundingTime[_token][msg.sender] <= block.timestamp, "Unbounding time not finished.");
        
        IERC20(_token).transfer(msg.sender, _amount);
        lockedBalances[_token][msg.sender] -= _amount;

        emit LockedTransferSent(_destAddr, _amount);
    }

    function depositERC20(ERC20 _token, uint256 _amount) public {
        uint256 erc20balance = IERC20(_token).balanceOf(msg.sender);
        require(_amount <= erc20balance, "balance is low");
        
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        ERC20Balances[_token][msg.sender] += _amount;

        emit TransferSent(msg.sender, _amount);
    }    

    function withdrawERC20(ERC20 _token, uint _amount, address payable _destAddr) public {
        require(_amount <= ERC20Balances[_token][msg.sender], "Insufficient funds");
        
        IERC20(_token).transfer(msg.sender, _amount);
        ERC20Balances[_token][msg.sender] -= _amount;

        emit TransferSent(_destAddr, _amount);
    }
    
    function depositNative() public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        
        nativeBalances[msg.sender] += msg.value;

        emit NativeTransferReceived(msg.sender, msg.value);
    }    

    function withdrawNative(uint _amount, address payable _destAddr) public {
        require(_amount <= nativeBalances[msg.sender], "Insufficient funds");
        
        _destAddr.transfer(_amount);

        nativeBalances[msg.sender] -= _amount;

        emit NativeTransferSent(_destAddr, _amount);
    }

    function lockNative(uint _timestamp) public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        
        nativeLockedBalances[msg.sender] += msg.value;
        nativeUnboundingTime[msg.sender] = _timestamp;
        
        emit NativeLockedTransferReceived(msg.sender, msg.value, _timestamp);


    }    

    function withdrawLockedNative(uint _amount, address payable _destAddr) public {
        require(_amount <= nativeLockedBalances[msg.sender], "Insufficient funds");
        require(nativeUnboundingTime[msg.sender] <= block.timestamp, "Unbounding time not finished.");

        _destAddr.transfer(_amount);

        nativeLockedBalances[msg.sender] -= _amount;

        emit NativeLockedTransferSent(_destAddr, _amount);
    }
}
