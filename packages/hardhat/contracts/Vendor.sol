pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    /////////////////
    /// Errors //////
    /////////////////

    error InvalidEthAmount();
    error InsufficientVendorTokenBalance(uint256 available, uint256 required);
    error EthTransferFailed(address to, uint256 amount);
    error InvalidTokenAmount();
    error InsufficientVendorEthBalance(uint256 available, uint256 required);
    event SellTokens(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);

    //////////////////////
    /// State Variables //
    //////////////////////

    uint256 public constant tokensPerEth = 100;

    YourToken public immutable yourToken;

    ////////////////
    /// Events /////
    ////////////////

    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function buyTokens() external payable {
        if (msg.value == 0) {
            revert InvalidEthAmount();
        }

        uint256 amountToBuy = msg.value * tokensPerEth;

        uint256 vendorBalance = yourToken.balanceOf(address(this));
        if (vendorBalance < amountToBuy) {
            revert InsufficientVendorTokenBalance({
                available: vendorBalance,
                required: amountToBuy
            });
        }

        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer tokens to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: ownerBalance}("");
        if (!sent) {
            revert EthTransferFailed(owner(), ownerBalance);
        }
    }

    function sellTokens(uint256 amount) public {
        if (amount == 0) {
            revert InvalidTokenAmount();
        }
        uint256 amountOfEthToTransfer = amount / tokensPerEth;
        if (address(this).balance < amountOfEthToTransfer) {
            revert InsufficientVendorEthBalance({
                available: address(this).balance,
                required: amountOfEthToTransfer
            });
        }
        yourToken.transferFrom(msg.sender, address(this), amount);
        (bool sent, ) = payable(msg.sender).call{value: amountOfEthToTransfer}("");
        if (!sent) {
            revert EthTransferFailed(msg.sender, amountOfEthToTransfer);
        }
        emit SellTokens(msg.sender, amount, amountOfEthToTransfer);
    }
}
