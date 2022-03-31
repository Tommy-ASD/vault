//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

abstract contract vault is IERC20 {
    mapping(address => mapping(address => uint256)) tokensDeposited;
    mapping(tokensDeposited => uint256) lockupPeriod;

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
        tokensDeposited[msg.sender][_tokenAddress] += _amount;
        emit deposited(
            msg.sender,
            _tokenAddress,
            _amount,
            tokensDeposited[msg.sender][_tokenAddress]
        );
    }

    function withdraw(address _tokenAddress, uint256 _amount) public {
        require(tokensDeposited[msg.sender][_tokenAddress] >= _amount);
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);
        tokensDeposited[msg.sender][_tokenAddress] -= _amount;
        emit withdrew(
            msg.sender,
            _tokenAddress,
            _amount,
            tokensDeposited[msg.sender][_tokenAddress]
        );
    }
}
