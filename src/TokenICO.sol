// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SampleToken} from "./SampleToken.sol";
import {UsdtToken} from "./UsdtToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenICO is Ownable, ReentrancyGuard {
    SampleToken public immutable sampleToken;
    UsdtToken public immutable usdtToken;

    // Constants
    uint256 public constant SOFT_CAP = 200_000 ether; // 200k tokens
    uint256 public constant HARD_CAP = 400_000 ether;
    uint256 public constant MIN_PURCHASE = 5 ether; // 20 tokens

    // 2 USDT per token
    uint256 public constant TOKEN_PRICE = 2;

    uint256 public totalSold;
    uint256 public immutable saleEndTime;
    bool public saleFinalized;

    mapping(address => uint256) public addressToContributions;

    event TokensPurchased(address indexed buyer, uint256 tokenAmount, uint256 ethPaid);
    event ICOFinalized(uint256 totalSold);

    constructor(address _sampleTokenAddress, address _UsdtTokenAddress, uint256 _duration) Ownable(msg.sender) {
        sampleToken = SampleToken(_sampleTokenAddress);
        usdtToken = UsdtToken(_UsdtTokenAddress);
        saleEndTime = block.timestamp + _duration;
    }

    function buyTokens(uint256 tokenAmount) external nonReentrant {
        require(block.timestamp < saleEndTime, "ICO: Sale ended");
        require(!saleFinalized, "ICO: Sale finalized");

        uint256 usdtAmount = tokenAmount * TOKEN_PRICE;
        require(tokenAmount >= MIN_PURCHASE, "ICO: Below min purchase");
        require(tokenAmount + totalSold <= HARD_CAP, "ICO: requested amount more than available tokens");

        require(usdtToken.transferFrom(msg.sender, address(this), usdtAmount), "ICO: Failed to transfer USDT from user");
        addressToContributions[msg.sender] += tokenAmount;
        totalSold += tokenAmount;

        require(sampleToken.transfer(msg.sender, tokenAmount), "ICO: Transfer failed");

        emit TokensPurchased(msg.sender, tokenAmount, usdtAmount);
    }

    function finalizeSale() external onlyOwner {
        require(block.timestamp >= saleEndTime, "ICO: Sale still active");
        require(!saleFinalized, "ICO: Already finalized");
        require(totalSold >= SOFT_CAP, "ICO: Soft cap not reached");

        // Transfer remaining balance to owner
        require(usdtToken.transfer(owner(), usdtToken.balanceOf(address(this))), "ICO: USDT transfer failed");

        saleFinalized = true;
        emit ICOFinalized(totalSold);
    }

    function withdrawIfFailed() external nonReentrant {
        require(block.timestamp >= saleEndTime, "ICO: Sale still active");
        require(totalSold < SOFT_CAP, "ICO: Soft cap reached");

        uint256 contribution = addressToContributions[msg.sender];
        require(contribution > 0, "ICO: No contribution");

        addressToContributions[msg.sender] = 0;
        sampleToken.transferFrom(msg.sender, owner(), contribution);

        require(usdtToken.transfer(msg.sender, contribution * TOKEN_PRICE), "ICO: USDT transfer failed");
    }
}
