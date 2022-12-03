class SVPKR_Rx_Pawn extends Rx_Pawn
config(Sniper_VP_Killer_Rewards);

var config bool DisableSniperBonusVP;

function bool IsSniperEquipped (Controller C)
{
	local class<Rx_Weapon> Weaps;

	if(C.Pawn != none && C.Pawn.Weapon != none)
	{
		Weaps = class<Rx_Weapon>(C.Pawn.Weapon.class) ;
		if(Weaps == class'Rx_Weapon_SniperRifle_GDI' 
			|| Weaps == class'Rx_Weapon_SniperRifle_Nod' 
			|| Weaps == class'Rx_Weapon_RamjetRifle'
			|| Weaps == class'Rx_Weapon_MarksmanRifle_GDI'
			|| Weaps == class'Rx_Weapon_MarksmanRifle_Nod')
			return true; 
	}
	
	return false; 
}



function string BuildDeathVPString(Controller Killer, class<DamageType> DamageType, bool Headshot, optional bool bUsingBlueprint)
{
	local string VPString;
	local int IntHolder; //Hold current number we'll be using 
	local int KillerVRank; 
	local float BaseVP;
	//local class<Rx_Vehicle> Killer_VehicleType; 
	local class<Rx_FamilyInfo> Victim_FamInfo;//Killer_FamInfo
	local string Killer_Location, Victim_Location; 
	local bool  KillerisPawn; //KillerisVehicle KillerInBase, KillerInEnemyBase, VictimInBase, VictimInEnemyBase, 
	local Rx_PRI KillerPRI; 
	local bool	bNeutral; //Only set to false if this is Offensive or Defensive 
	//Remember that -I- am the victim here
	//Begin by finding WHAT we are
	//if(Killer == none) return ""; 
	
	if((Rx_Controller(Killer) == none && Rx_Bot(Killer) == none)) return ""; 
	
	Victim_FamInfo=GetRxFamilyInfo();

	KillerPRI = Rx_PRI(Killer.PlayerReplicationInfo) ;
	
	bNeutral = true; 
	
	if(Rx_Vehicle(Killer.Pawn) != none ) //I got shot by a vehicool  
	{
		//KillerisVehicle = true; 
		//Killer_VehicleType = class<Rx_Vehicle>(Killer.Pawn.class); Shouldn't really come into play.
		//Get Veterancy Rank
		KillerVRank = Rx_Vehicle(Killer.Pawn).GetVRank(); 

	}
	else 
	//They're a Pawn, Harry
	if(Rx_Pawn(Killer.Pawn) != none )
	{
		KillerisPawn = true; 
		//Killer_FamInfo = Rx_Pawn(Killer.Pawn).GetRxFamilyInfo();
		//Get Veterancy Rank
		KillerVRank = Rx_Pawn(Killer.Pawn).GetVRank(); 
	}
	
	/*Finding location info*/ 
	
	IntHolder=Killer.GetTeamNum(); 

	Killer_Location = GetPawnLocation(Killer.Pawn); 
	
	IntHolder=GetTeamNum(); 
	
	Victim_Location = GetPawnLocation(self); 
	
	/*End Getting location*/
	
	//VP count starts here. 

	if (IsSniperEquipped(Killer))
	{
		// Get type of sniper
		if(ClassIsChildOf(Killer.Pawn.Weapon.Class,  class'Rx_Weapon_SniperRifle'))
			IntHolder = class'SVPKR_SniperVeterancyModifiers'.default.SniperRifleVetPercent;
		else if (ClassIsChildOf(Killer.Pawn.Weapon.Class,  class'Rx_Weapon_RamjetRifle'))
			IntHolder = class'SVPKR_SniperVeterancyModifiers'.default.RamjetRifleVetPercent;
		else if (ClassIsChildOf(Killer.Pawn.Weapon.Class,  class'Rx_Weapon_MarksmanRifle'))
			IntHolder = class'SVPKR_SniperVeterancyModifiers'.default.MarksmanRifleVetPercent;


		BaseVP = (Victim_FamInfo.default.VPReward[VRank] / 100) * IntHolder; 
		`Log("SVPKR: BaseVP for Kill of "$Victim_FamInfo.default.CharacterName$" with "$Killer.Pawn.Weapon.Class$" and sniper modifier at "$IntHolder$"\% is:" $BaseVP$" (Default: "$Victim_FamInfo.default.VPReward[VRank]$")");
	}
	else
		BaseVP = Victim_FamInfo.default.VPReward[VRank]; 	
	
	
	VPString = "[" $ GetCharacterClassName() @ "Kill]&+" $ BaseVP $ "&" ; 
	
	//Are THEY defending a beacon 
	
	if(NearEnemyBeacon()) //If we're near an enemy beacon 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_BeaconDefense;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim Near Enemy Beacon VP: "$IntHolder);
		
		if(KillerPRI != none)
			KillerPRI.AddBeaconKill(); 
		
		VPString = VPString $ "[Beacon Defence]&+" $ IntHolder $ "&";
	} 
		
		//Are WE defending an enemy beacon?
		
	if(NearFriendlyBeacon()) //If we're near a friendly beacon 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_BeaconAttack;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim Near Friendly Beacon VP: "$IntHolder);
		
		VPString = VPString $ "[Beacon Offence]&+" $ IntHolder $ "&";
	} 
	
	if(IHaveABeacon() ) //If we were carrying a beacon 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_BeaconHolderKill;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim Has Beacon VP: "$IntHolder);
		
		VPString = VPString $ "[Beacon Prevention]&+" $ IntHolder $ "&";
	} 
	
	if(Headshot) //If we got headshot-ed
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_Headshot;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Headshot VP: "$IntHolder);
		
		VPString = VPString $ "[HEADSHOT]&+" $ IntHolder $ "&";
	} 
		
	if(KillerisPawn && IsSniper() ) //If we're a sniper class
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_SniperKilled;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim Is Sniper VP: "$IntHolder);
		
		VPString = VPString $ "[Sniper Killed]&+" $ IntHolder $ "&";
	} 


		
	if(WasSniper(Killer)) //If we're a sniper class
	{		

		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_SniperKill;	

		if (DisableSniperBonusVP)
			`Log("SVPKR: Sniper VP Bonus Disabled (Usually: "$IntHolder$")");
		else
		{
			`Log("SVPKR: Sniper VP Bonus Enabled (Bonus Amount: "$IntHolder$")");
			BaseVP+=IntHolder;
		
			VPString = VPString $ "[Sniper Kill]&+" $ IntHolder $ "&";
		}
	}
		
	if(VRank > KillerVRank ) //Ya' done got fucked, son  [Negative Modifiers] (Leave out the '+') 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_Disadvantage*(VRank - KillerVRank);	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim Rank Is Higher Than Killer Rank VP: "$IntHolder);
		
		VPString = VPString $ "[Disadvantage]&+" $ IntHolder $ "&";
	} 
		
	if( PawnInFriendlyBase(Victim_Location, self) ) // Getting wrecked in your own base
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_AssaultKill;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Victim In Own Base VP: "$IntHolder);
		
		if(KillerPRI != none)
			KillerPRI.AddOffensiveKill(); 
		
		bNeutral = false; 
		
		VPString = VPString $ "[Offensive Kill]&+" $ IntHolder $ "&";
	} 
		
	/********************/
	/*Negative Modifiers*/
	/********************/
		
	if(KillerVRank > VRank ) //Is this bastard gimping ? [Negative Modifiers] (Leave out the '+') 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_UnfairAdvantage*(KillerVRank-VRank);	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Killer Rank Is Higher Than Victim VP: "$IntHolder);
		
		VPString = VPString $ "[Vet Advantage]&" $ IntHolder $ "&";
	} 
		
	if(DamageType == class'Rx_DmgType_ProxyC4' ) //Kills with mines 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_MineKill;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Mine Used VP: "$IntHolder);
		
		if(KillerPRI != none)
			KillerPRI.AddMineKill(); 
		
		VPString = VPString $ "[Mine Kill]&" $ IntHolder $ "&";
	} 
		
	if( PawnInFriendlyBase(Killer_Location, Killer.Pawn) ) //Is this bastard in his own base ? [Negative Modifiers] (Leave out the '+') 
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_DefenseKill;	
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Killer In Own Base VP: "$IntHolder);
		
		if(KillerPRI != none)
			KillerPRI.AddDefensiveKill(); 
		
		if(IsInfiltrator()){
			KillerPRI.AddInfiltratorKill();
		}
		
		bNeutral = false; 
		
		VPString = VPString $ "[Defensive Kill]&" $ IntHolder $ "&";
	} 
	if( bUsingBlueprint)
	{
		IntHolder = class'Rx_VeterancyModifiers'.default.Mod_BlueprintKill;	// I mean.... guard tower and turret really really makes things easy
			
		BaseVP+=IntHolder;
		//`Log("SVPKR: Placed Defence Kill VP: "$IntHolder);		
		VPString = VPString $ "[Defense Emplacement Kill]&" $ IntHolder $ "&";
	}
		
	BaseVP=fmax(1.0, BaseVP); //Offer at least 1 VP cuz... why not ? Consolation prize
		
	if(KillerPRI != none)
		KillerPRI.AddTotalKill(); 
	
	if(bNeutral)
		KillerPRI.AddNeutralKill(); 

	`Log("SVPKR: Rewarded VP: "$BaseVP);
		
	return "[" $ GetCharacterClassName() @ "Kill]&+" $ BaseVP $ "&" ;
		
	//Uncomment to use full feat strings 
	//return VPString ; /*Complicated for the sake of you entitled, ADHD kids that need flashing lights to pet your ego. BaseVP$"&"$*/
}