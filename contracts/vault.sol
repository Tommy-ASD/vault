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
    /// @dev vaults stored as NFTs?
    mapping(address => mapping(address => mapping(uint256 => userBalance)))
        private _tokensDeposited;

    //TODO: add time requirement
    struct userBalance {
        uint256 amount;
        bool timeLockIsActive;
        uint256 timelock;
        bool blockLockIsActive;
        uint256 blocklock;
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

    /// @param locked is a userBalance struct
    modifier lock(userBalance memory locked) {
        if (locked.timeLockIsActive) {
            require(locked.timelock >= block.timestamp);
        }
        if (locked.blockLockIsActive) {
            require(locked.blocklock >= block.number);
        }
        _;
    }

    modifier timelock(userBalance memory locked) {
        /// @notice locked.timelock is defined as the current timestamp of the block it is created at + the amount of time it should be locked for
        require(locked.timeLockIsActive);
        require(locked.timelock >= block.timestamp);
        _;
    }

    modifier blocklock(userBalance memory locked) {
        require(locked.blockLockIsActive);
        require(locked.blocklock >= block.number);
        _;
    }

    function depositByTimelock(
        address _tokenAddress,
        uint256 _amount,
        uint256 _time
    ) public {
        IERC20 token = IERC20(_tokenAddress);
        //can't transfer from unless approved
        require(token.allowance(msg.sender, address(this)) >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        //create new userBalance struct
        _tokensDeposited[msg.sender][_tokenAddress][
            _userNonce[msg.sender]
        ] = userBalance(_amount, true, block.timestamp + _time, false, 0);
        _userNonce[msg.sender] += 1;
    }

    function depositByBlocklock(
        address _tokenAddress,
        uint256 _amount,
        uint256 _blocks
    ) public {
        IERC20 token = IERC20(_tokenAddress);
        //can't transfer from unless approved
        require(token.allowance(msg.sender, address(this)) >= _amount);
        token.transferFrom(msg.sender, address(this), _amount);
        //create new userBalance struct
        _tokensDeposited[msg.sender][_tokenAddress][
            _userNonce[msg.sender]
        ] = userBalance(_amount, false, 0, true, block.number + _blocks);
        _userNonce[msg.sender] += 1;
    }

    function depositByPricelock() public {
        /// will start once DEX is finished
    }

    /// @param _tokenAddress is the address of the token deposited
    /// @param _nonce is the depositID
    /// @param _amount is the amount user wants to withdraw
    function withdraw(
        address _tokenAddress,
        uint256 _nonce,
        uint256 _amount
    ) public timelock(_tokensDeposited[msg.sender][_tokenAddress][_nonce]) {
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
