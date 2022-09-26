// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PairVetting is Ownable
{    
	using SafeMath for uint256;

	address public gameManager = 0x4B129178704A94b112D7dF860C91986Fe11Ad23F;
	uint public claimDuration = 24 * 3600;
	uint public referrlRate = 2;

	struct winner
	{
		address wallet;
		uint amount;
		string idOnDB;
	}
	mapping( address => uint256 ) refAwardAmount;
	mapping( address => uint256 ) countOfRerrals;
  	mapping( address => uint256 ) claimedTime;

	event StartOfVetting(address wallet, string pairId ,uint pairPrice, uint amount, uint vettingPeriod, bool upOrDown);
	event EndOfVetting(winner[] winners);
	event Maintenance(address owner, uint tokenBalance, uint nativeBalance);
	event ChangedGameManager(address owner, address newManager);
	event ChangedClaimDuration(address owner, uint newDuration);
	event ClaimedAward(address wallet, uint awardAmount);
	event ChangedReferralRate(address owner, uint newRate);
	
	function changeClaimDuration(uint newDuration) external {
		require(msg.sender == gameManager || msg.sender == owner(), "104");
		claimDuration = newDuration;
		emit ChangedClaimDuration(owner(), claimDuration);
	}

	function enterVetting(string memory pairId, uint pairPrice, uint vettingPeriod, bool upOrDown, address ref) external payable    
	{		
		uint amount = msg.value;
		uint awardAmount = amount.mul(referrlRate).div(100);
		refAwardAmount[ref] += awardAmount;
		countOfRerrals[ref] += 1;		
		emit StartOfVetting(msg.sender, pairId, pairPrice, amount - awardAmount, vettingPeriod, upOrDown);
	}

	function changeGameManager(address newAddr) external {
		require(msg.sender == gameManager || msg.sender == owner(), "104");
		gameManager = newAddr;
		emit ChangedGameManager(owner(), gameManager);
	}

	function changeReferralRate(uint newRate) external {
		require(msg.sender == gameManager || msg.sender == owner(), "104");
		require(newRate>=0 && newRate<=100, "105");
		referrlRate = newRate;
		emit ChangedReferralRate(owner(), referrlRate);
	}

	function getClaimableInformation(address user) public view returns(uint, uint, uint) {
		return (refAwardAmount[user], countOfRerrals[user], claimedTime[user]);
	}

	function claimReferralAwards(address user) external {
		require( refAwardAmount[user] > 0, "103");
    	require( claimedTime[user] + claimDuration > block.timestamp, "102" );
		require( address(this).balance > refAwardAmount[user], "101");

 		payable(user).transfer(refAwardAmount[user]);
		emit ClaimedAward(user, refAwardAmount[user]);

		refAwardAmount[user] = 0;
		countOfRerrals[user] = 0;
		claimedTime[user] = block.timestamp;
	}

	function endVetting(winner[] memory winners) external
	{
		require(msg.sender == gameManager);
		for(uint idx = 0; idx<winners.length; idx++)
		{
				uint256 nativeBal = address(this).balance;
				require(nativeBal > winners[idx].amount, "101");
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
