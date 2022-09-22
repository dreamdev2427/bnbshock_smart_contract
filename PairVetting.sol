// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PairVetting is Ownable
{    
	using SafeMath for uint256;

	address public gameManager = 0x3745CCE8D73fF51376B1B3E5639f290EE5147187;

	struct winner
	{
		address wallet;
		uint amount;
		string idOnDB;
	}

	event StartOfVetting(address wallet, string pairId ,uint pairPrice, uint amount, uint vettingPeriod, bool upOrDown);
	event EndOfVetting(winner[] winners);
	event Maintenance(address owner, uint tokenBalance, uint nativeBalance);
	event ChangedGameManager(address owner, address newManager);
	
	function changeGameManager(address _newAddr) external onlyOwner
	{
		gameManager = _newAddr;
		emit ChangedGameManager(owner(), gameManager);
	}

	function updateGameManagerAddress(address newAddr) external {
	    require(msg.sender == gameManager);
	    gameManager = newAddr;
	}

	function enterVetting(string memory pairId, uint amount, uint pairPrice, uint vettingPeriod, bool upOrDown) external payable    
	{
		emit StartOfVetting(msg.sender, pairId, amount, pairPrice, vettingPeriod, upOrDown);
	}

	function endVetting(winner[] memory winners) external
	{
	    require(msg.sender == gameManager);
        for(uint idx = 0; idx<winners.length; idx++)
        {
            uint256 nativeBal = address(this).balance;
            require(nativeBal > winners[idx].amount, "Not enough funds.");
            address payable mine = payable(winners[idx].wallet);
            mine.transfer(winners[idx].amount);    
        }
		emit EndOfVetting(winners); 
	}

	function withdraw(address _addr) external onlyOwner
	{
	    require(msg.sender == owner());
		uint256 balance = IERC20(_addr).balanceOf(address(this));
		if(balance > 0) {
            IERC20(_addr).transfer(msg.sender, balance);
		}
		uint256 nativeBal = address(this).balance;
		if(nativeBal> 0) {
			payable(msg.sender).transfer(nativeBal);
		}
		emit Maintenance(msg.sender, balance, nativeBal);
	}	
}
