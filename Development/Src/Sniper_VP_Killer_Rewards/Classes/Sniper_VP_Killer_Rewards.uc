class Sniper_VP_Killer_Rewards extends Rx_Mutator;
/**
*
    Author: PieMan
    Name: Sniper_VP_Killer_Rewards
    Description: Allows the configuration of the amount of veterancy points a player is rewarded when killing another player.
    Config: UDKSniper_VP_Killer_Rewards.ini
*
*/

function bool CheckReplacement(Actor Other) 
{
   Rx_Game(WorldInfo.Game).DefaultPawnClass = class'SVPKR_Rx_Pawn';

   return true;
}