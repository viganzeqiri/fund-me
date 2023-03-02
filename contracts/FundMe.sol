// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceConvertor.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughFunds();
error FundMe__WithdrawFailed();

/**
 * @title A contract for crown funding
 * @author Vigan Zeqiri
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;
    address private immutable i_owner;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MIN_USD) {
            revert FundMe__NotEnoughFunds();
        }

        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        // 1. transfer
        // payable(msg.sender).transfer(address(this).balance);

        // 2. send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // if (!sendSuccess) {
        //     revert WithdrawFailed();
        // }

        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert FundMe__WithdrawFailed();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
