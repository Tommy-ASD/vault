//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

abstract contract vault is IERC20 {
    //definitely optimizable
    mapping(address => uint256) private _userNonce;
    mapping(address => mapping(uint256 => userBalance))
        private _tokensDeposited;

    struct userBalance {
        address tokenAddress;
        uint256 amount;
    }

    event deposited(
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 newBalance
    );
    event withdrew(
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 newBalance
    );

    constructor() {}

    function deposit(address _tokenAddress, uint256 _amount) public {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);
        _tokensDeposited[msg.sender][_userNonce[msg.sender]] = userBalance(
            _tokenAddress,
            _amount
        );
        _userNonce[msg.sender] += 1;
    }

    /// @param _tokenAddress is the address of the token deposited
    /// @param _nonce is the depositID
    /// @param _amount is the amount user wants to withdraw
    function withdraw(
        address _tokenAddress,
        uint256 _nonce,
        uint256 _amount
    ) public {
        /// @dev _tokensDeposited[msg.sender][_nonce].(insert var name) points to a userBalance struct
        /// @dev _tokensDeposited maps an address (msg.sender) to a uint256 (_nonce)
        /// @dev It then maps that uint to a userBalance struct
        /// @dev That userBalance struct has an amount and a tokenAddress
        require(
            _tokensDeposited[msg.sender][_nonce].tokenAddress == _tokenAddress,
            "That is not the correct token"
        );
        require(
            _tokensDeposited[msg.sender][_nonce].amount >= _amount,
            "Cannot withdraw more than deposited"
        );
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);
        _tokensDeposited[msg.sender][_nonce].amount -= _amount;
    }
}
