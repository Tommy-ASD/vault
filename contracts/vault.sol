//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

/// @dev audit is definitely necessary
/// @dev i lost track of what i was doing a long time ago
/// @dev i continued doing it

abstract contract vault is IERC20 {
    //definitely optimizable
    mapping(address => uint256) private _userNonce;

    /// @dev maps user address to token address
    /// @dev maps token address to nonce
    /// @dev maps nonce to userBalance struct
    mapping(address => mapping(address => mapping(uint256 => userBalance)))
        private _tokensDeposited;

    struct userBalance {
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
        require(token.allowance(msg.sender, address(this)) >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        _tokensDeposited[msg.sender][_tokenAddress][
            _userNonce[msg.sender]
        ] = userBalance(_amount);
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
        /// @dev _tokensDeposited[msg.sender][_tokenAddress][_nonce] points to a userBalance struct
        /// @dev _tokensDeposited maps an address (msg.sender) to a token address (_tokenAddress)
        /// @dev It then maps that _tokenAddress to a uint (_nonce)
        /// @dev That uint maps to a userBalance struct
        /// @dev that userBalance struct has a few variables
        require(
            _tokensDeposited[msg.sender][_tokenAddress][_nonce].amount >=
                _amount,
            "Cannot withdraw more than deposited"
        );
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);
        _tokensDeposited[msg.sender][_tokenAddress][_nonce].amount -= _amount;
    }
}
