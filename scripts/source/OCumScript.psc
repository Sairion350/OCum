ScriptName OCumScript Extends Quest

;needs StorageUtils from papyrusutils
int property CheckCumKey auto

int property squirtchance auto
OsexIntegrationMain ostim 
string CumStoredKey
string LastCumCheckTimeKey
string MaxCumVolumeKey
actor playerref

Osexbar CumBar

spell cumSpell1
spell cumSpell2
spell cumSpell3
spell cumSpell4

Activator CumLauncher

armor UrethraNode

sound cumSound 
sound squirtSound
sound femaleGasp

armor Squirt1
armor Squirt2
armor Squirt3

Event OnInit()

	debug.Notification("OCum installed")
	

	ostim = game.GetFormFromFile(0x000801, "Ostim.esp") as OsexIntegrationMain
	playerref = game.GetPlayer()

	console("OCum installed")

	if ostim.GetAPIVersion() < 7
		debug.MessageBox("Your ostim version is out of date. update now")
	endif

	CheckCumKey = 157

	CumStoredKey = "CumStoredAmount"
	LastCumCheckTimeKey = "CumLastCalcTime"
	MaxCumVolumeKey = "CumMaxAmount"
	CumBar = (Self as Quest) as Osexbar
	InitBar(cumbar)

	cumSpell1 = game.GetFormFromFile(0x00080E, "OCum.esp") as spell
	cumSpell2 = game.GetFormFromFile(0x00080f, "OCum.esp") as spell
	cumSpell3 = game.GetFormFromFile(0x000810, "OCum.esp") as spell
	cumSpell4 = game.GetFormFromFile(0x000811, "OCum.esp") as spell

	CumLauncher = game.GetFormFromFile(0x000817, "OCum.esp") as Activator

	UrethraNode = game.GetFormFromFile(0x000818, "OCum.esp") as armor

	Squirt1 = game.GetFormFromFile(0x00574E, "OCum.esp") as armor
	Squirt2 = game.GetFormFromFile(0x00574F, "OCum.esp") as armor
	Squirt3 = game.GetFormFromFile(0x005750, "OCum.esp") as armor

	cumSound = game.GetFormFromFile(0x00574D, "OCum.esp") as sound
	squirtSound = game.GetFormFromFile(0x007EF0, "OCum.esp") as sound
	femaleGasp = game.GetFormFromFile(0x007EF1, "OCum.esp") as sound

	cummedOnActs = new actor[1]

	squirtchance = 25

	ResetQRand()
	OnLoad()

	;Utility.Wait(5)
	;TempDisplayBar()
EndEvent

bool function PlayerIsMale()
	return !ostim.IsFemale(playerref)
EndFunction

Event OstimRedressEnd(string eventName, string strArg, float numArg, Form sender)
	console("OCum Cleaning up armors...")

	actor dom = ostim.GetDomActor()
	actor sub = ostim.GetSubActor()
	actor third = ostim.GetThirdActor()

	if dom 
		dom.RemoveItem(UrethraNode, 99, true)
		dom.RemoveItem(squirt1, 99, true)
	endif
	if sub 
		sub.RemoveItem(UrethraNode, 99, true)
		sub.RemoveItem(squirt1, 99, true)
	endif
	if third 
		third.RemoveItem(UrethraNode, 99, true)
		third.RemoveItem(squirt1, 99, true)
	endif
EndEvent

Event OstimOrgasm(string eventName, string strArg, float numArg, Form sender)
	ostim.SetOrgasmStall(true)
	actor orgasmer = ostim.GetMostRecentOrgasmedActor()
	bool male = !ostim.IsFemale(orgasmer)

	if male 

		ostim.PlaySound(orgasmer, cumsound)
		float CumAmount
		float MaxStorage = GetMaxCumStoragePossible(orgasmer)
		float idealMax = (MaxStorage / 2) + (MaxStorage * Utility.RandomFloat(-0.15, 0.15))
		float currentCum = GetCumStoredAmount(orgasmer)

		actor partner = ostim.GetSexPartner(orgasmer)
		bool malePartner = !ostim.IsFemale(partner)

		if idealMax < currentCum
			cumamount = idealMax
		else 
			cumamount = currentCum 
		endif 

		console("Blowing load size: " + CumAmount + " ML")
		SendModEvent("ocum_cum", NumArg = CumAmount)
		AdjustStoredCumAmount(orgasmer, 0 - CumAmount)


		ApplyCumAsNecessary(orgasmer, partner, CumAmount)
		if ostim.IsVaginal() 
			if !malePartner ; give it to female
				AdjustStoredCumAmount(partner, CumAmount)
			endif
		endif

		CumShoot(orgasmer, cumamount)
		if (orgasmer == playerref)|| (partner == playerref)
			ostim.SetOrgasmStall(false) ;
			TempDisplayBar()
		endif


	else 
		if ostim.ChanceRoll(50)
			ostim.PlaySound(orgasmer, femaleGasp)
		endif
		if ostim.ChanceRoll(squirtchance)
			Squirt(orgasmer)
		endif
	endif
	ostim.SetOrgasmStall(false)
EndEvent

float function GetMaxCumStoragePossible(actor npc)
	
	if ostim.IsFemale(npc)
		float max = GetNPCDataFloat(npc, MaxCumVolumeKey)
		if (max != -1)
			return max 
		else 
			max = Utility.RandomFloat(15, 56)
			console("Uterine volume for " + npc.GetDisplayName() + ":" + max)
			StoreNPCDataFloat(npc, MaxCumVolumeKey, max)
			return max
		EndIf
	else 
			return 2 * ( (npc.GetLevel() * 0.5) + 1)
	endif
EndFunction

function AdjustStoredCumAmount(actor npc, float amount)
	float set
	float current = GetCumStoredAmount(npc)
	float max = GetMaxCumStoragePossible(npc)

	if (current + amount) > max
		if ostim.IsFemale(npc)
			set = current + amount 
			float ratio = set / max
			ratio -= 1
			float inflation = ratio * 0.6
			if inflation > 0.6
				inflation = 0.6
			EndIf
			SetBellyScale(npc, inflation)
		else 
			set = max
		endif
	elseif (current + amount) < 0
		set = 0
	else 
		set = current + amount 
	endif 

	StoreNPCDataFloat(npc, CumStoredKey, set)
endfunction

float function GetCumStoredAmount(actor npc)
	float lastCheckTime = GetNPCDataFloat(npc, LastCumCheckTimeKey)
	StoreNPCDataFloat(npc, LastCumCheckTimeKey, utility.GetCurrentGameTime())

	if ostim.IsFemale(npc)
		if lastCheckTime == -1 ;never calculated
			StoreNPCDataFloat(npc, CumStoredKey, 0.0)
			return 0
		else 
			float cum = GetNPCDataFloat(npc, CumStoredKey)

			;intervaginal sperm will disolve at a rate of 1ml/4hrs (.166 days = 4 hours)
			float currenttime = Utility.GetCurrentGameTime()
			float timePassed = currenttime - lastCheckTime

			float cumToRemove = timePassed / 0.166

			cum = cum - cumToRemove

			StoreNPCDataFloat(npc, CumStoredKey, cum)

			return cum
		endif
	else 
		float cum = GetNPCDataFloat(npc, CumStoredKey)
		; sperm will regen at a rate of max storage/day
		float currenttime = Utility.GetCurrentGameTime()
		float timePassed = currenttime - lastCheckTime
		float max = GetMaxCumStoragePossible(npc)

		float cumToAdd = timePassed * max

		cum = cum + cumToAdd
		if cum > max 
			cum = max 
		endif 

		StoreNPCDataFloat(npc, CumStoredKey, cum)
		return cum
	endif 

EndFunction

function StoreNPCDataFloat(actor npc, string keys, Float num) ; don't call this for getting cum stuff, call the function up above.
	StorageUtil.SetFloatValue(npc as form, keys, num)
	;console("Set value " + num + " for key " + keys)
EndFunction

Float function GetNPCDataFloat(actor npc, string keys)
	return StorageUtil.GetFloatValue(npc, keys, -1)
EndFunction

function FireCumBlast(objectreference base, ObjectReference angle, int amount, actor act)
	spell cum
	if amount == 1
		cum = cumSpell1
	elseif amount == 2
		cum = cumSpell2
	elseif amount == 3
		cum = cumSpell3
	elseif amount == 4
		cum = cumSpell4
	endif

	cum.Cast(base, aktarget = angle)
	ostim.PlaySound(act, cumsound)
EndFunction

; Load size
;none: 0 ml
;Small: 0 - 3 ml
;Medium: 3 - 8 ml
;Large: 8 - 16 ml
;Massive 16 ml+

int function GetLoadSizeFromML(float ml)
	if ml < 0.1
		return 0
	elseif ml < 3.0
		return 1
	elseif ml < 8.0
		return 2
	elseif ml < 16
		return 3
	else
		return 4
	endif 
endfunction 

Function Squirt(actor act)
	console("Squirting")

	int i = 0 
	int max = Utility.RandomInt(2, 6)

	While i < max 
		SquirtShoot(act)

		i += 1
	EndWhile

EndFunction

function SquirtShoot(actor act)
	ostim.PlaySound(act, squirtsound)
	act.EquipItem(squirt1, abPreventRemoval = True, abSilent = True)  ; don't do AddItem first, it will make NPCs redress 
	if ostim.IsInFreeCam() && act == playerref
		act.QueueNiNodeUpdate()
	endif

	Utility.wait(Utility.RandomFloat(0.7, 1.0))

	bool cam = false
	if ostim.IsInFreeCam() && (act == playerref)
		ostim.ToggleFreeCam(false)
		cam = true
	endif
	act.UnequipItem(squirt1, true, true)
	if cam 
		ostim.ToggleFreeCam(true)
	endif
endfunction

function CumShoot(actor act, float amountML)

	
	int size = GetLoadSizeFromML(amountml)
	if size == 0
		return 
	endif
	
	int numSpurts 
	float Frequency 
	int doubleFireChance = 15
	int tripleFireChance = 10
	int inaccuracy = 60

	if size == 1
		Frequency = Utility.RandomFloat(0.8, 1.2)
		inaccuracy = 40
	elseif size == 2
		Frequency = Utility.RandomFloat(0.3, 0.7)
		inaccuracy = 45
	elseif size == 3
		Frequency = Utility.RandomFloat(0.1, 0.3)
		inaccuracy = 55
	elseif size == 4
		Frequency = Utility.RandomFloat(0.1, 0.3)
		doubleFireChance = 85
		tripleFireChance = 30
		inaccuracy = 60
	endif

	numSpurts = Math.ceiling(amountML) + 2

	SetUrethra(act)
	int i = 1
	ObjectReference caster = act.PlaceAtMe(CumLauncher)
	ObjectReference target = act.PlaceAtMe(CumLauncher)  ; to aim the spell in the correct direction
	Float[] uPos = new Float[3]
	Float[] uRM = new Float[9]
	Float targetX
	float targetY
	float targetZ
	NetImmerse.GetNodeWorldPosition(act, "Urethra", uPos, False) ;setting arrays like this is possible apparently...........
	caster.SetPosition(uPos[0], uPos[1], uPos[2])
	NetImmerse.GetNodeWorldRotationMatrix(act, "Urethra", uRM, False)  ; (uRM[1] uRM[4] uRM[7]) is the direction vector for the spurts to be launched (local y axis of the node)
	while (i < numSpurts) && ostim.AnimationRunning()
		
		;aiming 
		targetX = uPos[0] + uRM[1] * 200.0 + QRand(0-inaccuracy, inaccuracy)
		targetY = uPos[1] + uRM[4] * 200.0 + QRand(0-inaccuracy, inaccuracy)
		targetZ = uPos[2] + uRM[7] * 200.0 + QRand(-10.0, 10.0) - ((i as Float) / (numSpurts as Float) - 0.5) * 180.0  ; later spurts fly lower, and (usually) less distance
		target.SetPosition(targetX, targetY, targetZ) 

		bool doublefire = ostim.ChanceRoll(doubleFireChance)
		bool tripleFire = false
		if doublefire
			tripleFire = ostim.ChanceRoll(tripleFireChance)
		endif
	
		FireCumBlast(caster, target, Utility.RandomInt(1, 4), act)
		if doublefire
			targetX = targetX + QRand(0-inaccuracy, inaccuracy)
			targetY = targetY + QRand(0-inaccuracy, inaccuracy)
			target.SetPosition(targetX, targetY, targetZ) 

			Utility.Wait(QRand(0.025, 0.075))
			FireCumBlast(caster, target, Utility.RandomInt(1, 4), act)
			if tripleFire
				targetX = targetX + QRand(0-inaccuracy, inaccuracy)
				targetY = targetY + QRand(0-inaccuracy, inaccuracy)
				target.SetPosition(targetX, targetY, targetZ) 

				Utility.Wait(QRand(0.025, 0.075))
				FireCumBlast(caster, target, Utility.RandomInt(1, 4), act)
			endif
		endif


		Utility.Wait(Frequency)

	i += 1
	EndWhile

	caster.delete()
	target.delete()
	

endfunction

function SetUrethra(actor a)
;	bool cam = false
;	if ostim.IsInFreeCam()
;		ostim.ToggleFreeCam(false)
;		cam = true
;	endif
	a.EquipItem(UrethraNode, abPreventRemoval = True, abSilent = True)  ; don't do AddItem first, it will make NPCs redress 
	if ostim.IsInFreeCam() && a == playerref
		a.QueueNiNodeUpdate()
	endif

	bool isFemale = ostim.IsFemale(a)

	Float[] move0 = new Float[3]
	Float[] move100 = new Float[3]
	Float[] rotate = new Float[3]
	Float[] move = new Float[3]

	Float aWeight = a.GetActorBase().GetWeight()

	move0[0] = 0
	move0[1] = -0.5
	move0[2] = 0.1
	move100[0] = 0
	move100[1] = 0.4
	move100[2] = 0.3
	rotate[0] = 0
	rotate[1] = 0
	rotate[2] = -3 + 10


	move[0] = move0[0] + (move100[0] - move0[0]) * aWeight / 100.0  ; interpolate between body weight 0 and 100
	move[1] = move0[1] + (move100[1] - move0[1]) * aWeight / 100.0
	move[2] = move0[2] + (move100[2] - move0[2]) * aWeight / 100.0

	Utility.Wait(0.05)

	NiOverride.AddNodeTransformPosition(a, False, isFemale, "Urethra", "SLCCumAdjust", move)
	NiOverride.AddNodeTransformRotation(a, False, isFemale, "Urethra", "SLCCumAdjust", rotate)
	NiOverride.UpdateNodeTransform(a, False, isFemale, "Urethra")
EndFunction

Event OnKeyDown(Int KeyPress)
	if KeyPress == CheckCumKey
		TempDisplayBar()
	endif
EndEvent


Function OnLoad()
	RegisterForModEvent("ostim_orgasm", "OstimOrgasm")
	RegisterForModEvent("ostim_redresscomplete", "OstimRedressEnd")
	RegisterForKey(CheckCumKey)
EndFunction

function console(string in)
	OsexIntegrationMain.Console(in)
EndFunction

function TempDisplayBar()
	cumbar.SetPercent(GetCumStoredAmount(playerref) / GetMaxCumStoragePossible(playerref))
	SetBarVisible(cumbar, true)
	Utility.wait(10)
	SetBarVisible(cumbar, false)
Endfunction

Function InitBar(Osexbar Bar)
	Bar.HAnchor = "left"
	Bar.VAnchor = "bottom"
	Bar.X = 980.0
	Bar.Alpha = 0.0
	Bar.SetPercent(0.0)
	Bar.FillDirection = "Left"

	
	Bar.Y = 120.0
	Bar.SetColors(0xb0b0b0, 0xfff5fd)


	SetBarVisible(Bar, False)
EndFunction

Function SetBarVisible(Osexbar Bar, Bool Visible)
	If (Visible)
		Bar.FadeTo(100.0, 1.0)
		Bar.FadedOut = False
	Else
		Bar.FadeTo(0.0, 1.0)
		Bar.FadedOut = True
	EndIf
EndFunction



; God damn erstam did some crazy shit with cumshot

; A Wichmann-Hill random number generator
; used to avoid suspending script execution by making external calls to Utility.RandomFloat()
Float Function QRand(Float min = 0.0, Float max = 1.0)
	rnd_s1 = (171 * rnd_s1) % 30269
	rnd_s2 = (172 * rnd_s2) % 30307
	rnd_s3 = (170 * rnd_s3) % 30323
	Float r = rnd_s1 / 30269.0 + rnd_s2 / 30367.0 + rnd_s3 / 30323.0
	r -= (r as Int)
	Return  r * (max - min) + min
EndFunction


; Set initial seed values for the RNG. Can also be called from MCM if generation gets stuck on always the same values.
Function ResetQRand()
	Int realTimeMod = (Utility.GetCurrentRealTime() as Int) + (utility.randomint(1, 150)) % 1000
	rnd_s1 = 13254 + realTimeMod
	rnd_s2 = 4931 + realTimeMod
	rnd_s3 = 24178 + realTimeMod
EndFunction

int rnd_s1
int rnd_s2
int rnd_s3



function ApplyCumAsNecessary(actor male, actor sub, float amountML)
	
	int intensity = GetLoadSizeFromML(amountML)

	if intensity == 0
		return 
	endif 
	console("Applying cum")

		int pattern = GetCumPattern()

		if pattern == 3
			if intensity == 2
				CumOnto(sub, "Anal1")
			elseif intensity == 3
				if ostim.ChanceRoll(50)
					CumOnto(sub, "Anal2")
				else 
					CumOnto(sub, "Anal1")
				endif 
			elseif intensity == 4
				CumOnto(sub, "Anal3")
				if ostim.ChanceRoll(75)
					CumOnto(sub, "Anal1")
				endif 
				if ostim.ChanceRoll(75)
					CumOnto(sub, "Anal2")
				endif 
			endif
		elseif pattern == 1
			if intensity == 2
				CumOnto(sub, "Vaginal1")
			elseif intensity == 3
				if ostim.ChanceRoll(50)
					if ostim.ChanceRoll(50)
						CumOnto(sub, "Vaginal2")
					else 
						CumOnto(sub, "Vaginal2Alt")
					endif
				else 
					CumOnto(sub, "Vaginal1")
				endif 
			elseif intensity == 4
				CumOnto(sub, "Vaginal3")
				if ostim.ChanceRoll(75)
					CumOnto(sub, "Vaginal1")
				endif 
				if ostim.ChanceRoll(75)
					if ostim.ChanceRoll(50)
						CumOnto(sub, "Vaginal2")
					else 
						CumOnto(sub, "Vaginal2Alt")
					endif
				endif 
			endif
		elseif pattern == 2

			string cclass = ostim.GetCurrentAnimationClass()
			if cclass == "HhBj" || cclass == "BJ"
				if ostim.ChanceRoll(50)
					return 
				endif
			endif 

			if (intensity == 2) || (intensity == 1)
				if ostim.ChanceRoll(50)
					CumOnto(sub, "Oral1")
				else 
					CumOnto(sub, "Oral1Alt")
				endif
			elseif intensity == 3
				CumOnto(sub, "Oral2")
				if ostim.ChanceRoll(50)
					if ostim.ChanceRoll(50)
						CumOnto(sub, "Oral1")
					else 
						CumOnto(sub, "Oral1Alt")
					endif
				endif 
			elseif intensity == 4
				CumOnto(sub, "Oral2")
				CumOnto(sub, "Oral1")
				CumOnto(sub, "Oral1Alt")
				
			endif
		endif


endfunction

; 0 none
; 1 vaginal
; 2 oral
; 3 anal
int function GetCumPattern()
	string oclass = ostim.GetCurrentAnimationClass()
	if ostim.IsVaginal()
		return 1
	elseif oclass == "An"
		return 3
	elseif (oclass == "ApPJ") || (oclass == "HJ") || (oclass == "BJ") || (oclass == "ApPJ") || (oclass == "ApHJ")|| (oclass == "HhPJ") || (oclass == "HhBJ") || (oclass == "VBJ") || (oclass == "VHJ") || (oclass == "HhPo")
		return 2 
	elseif (oclass == "Po")
		String Pos = ostim.getodatabase().getPositionData(ostim.GetCurrentAnimationOID())
		string dompos = StringUtil.Split(Pos, "!")[0]
		string subpos = StringUtil.Split(Pos, "!")[1]

		bool domStanding = ostim.StringContains(dompos, "S")
		bool subStanding = ostim.StringContains(subpos, "S")
		bool SubKneeling = ostim.StringContains(subpos, "Kn") || ostim.StringContains(subpos, "C")
		bool DomKneeling = ostim.StringContains(dompos, "Kn") || ostim.StringContains(dompos, "C")
		bool subLaying = ostim.StringContains(subpos, "M") || ostim.StringContains(subpos, "PE") || ostim.StringContains(subpos, "D")
		bool domlaying = ostim.StringContains(dompos, "M") || ostim.StringContains(dompos, "PE") || ostim.StringContains(dompos, "D")

		if (domStanding && subStanding)
			return 1
		elseif (SubKneeling && domStanding)
			return 2
		elseif (sublaying && domkneeling)
			return 3
		elseif (sublaying && domlaying)
			return 1
		else 
			return 2
		endif
	endif

EndFunction

; Cum textures

; https://www.loverslab.com/files/file/2968-sexlab-cum-textures-remake-slavetats/
; https://www.loverslab.com/files/file/243-sexlab-sperm-replacer/ - permission from: https://www.loverslab.com/topic/32080-sexlab-sperm-replacer-3dm-forum-version/


function CumOnto(actor act, string TexFilename, bool body = true)
	console("Applying texture: " + TexFilename)
	string area
	if body 
		area = "Body"
	else 
		area = "Face"
	endif
	ReadyOverlay(act, ostim.AppearsFemale(act), area, GetCumTexture(TexFilename))
	cummedOnActs = PapyrusUtil.PushActor(cummedonacts, act)
	RegisterForSingleUpdate(300)
endfunction 

function RemoveCumTex(actor act)

	bool Gender = ostim.AppearsFemale(act)
	int i = 0
	int max = NiOverride.GetNumBodyOverlays()

	while i < max 
		String Node = "Body" + " [ovl" + i + "]"

		string tex = NiOverride.GetNodeOverrideString(act, Gender, Node, 9, 0)

		If ostim.StringContains(tex, "Cum")
			NiOverride.AddNodeOverrideString(act, Gender, Node, 9, 0, "actors\\character\\overlays\\default.dds", false)
			NiOverride.RemoveNodeOverride(act, Gender, node , 9, 0)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 7, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 0, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 8, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 2, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 3, -1)
		EndIf

		i += 1
	endwhile
	
	max = NiOverride.GetNumFaceOverlays()
	i = 0
	while i < max 
		String Node = "Face" + " [ovl" + i + "]"

		string tex = NiOverride.GetNodeOverrideString(act, Gender, Node, 9, 0)

		If ostim.StringContains(tex, "Cum")
			NiOverride.AddNodeOverrideString(act, Gender, Node, 9, 0, "actors\\character\\overlays\\default.dds", false)
			NiOverride.RemoveNodeOverride(act, Gender, node , 9, 0)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 7, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 0, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 8, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 2, -1)
			NiOverride.RemoveNodeOverride(act, Gender, Node, 3, -1)
		EndIf

		i += 1
	endwhile
endfunction


actor[] cummedOnActs
Event OnUpdate()
	int i 
	int max = cummedOnActs.Length

	while i < max 
		if cummedOnActs[i] != none 
			RemoveCumTex(cummedOnActs[i])
			RemoveBellyScale(cummedOnActs[i])
		endif
		i += 1
	endwhile

	cummedOnActs = new actor[1]
EndEvent

function SetBellyScale(actor akActor, float bellyScale)
	NiOverride.SetBodyMorph(akActor, "PregnancyBelly", "OCum", bellyScale)
	NiOverride.UpdateModelWeight(akActor)

	cummedOnActs = PapyrusUtil.PushActor(cummedonacts, akactor)
	RegisterForSingleUpdate(300)
EndFunction

function RemoveBellyScale(actor akActor)
	NiOverride.ClearBodyMorph(akActor, "PregnancyBelly", "OCum")
 	NiOverride.UpdateModelWeight(akActor)
endfunction

string function GetCumTexture(string filename)
	return "CumOverlays\\" + filename + ".dds"
EndFunction

Function ReadyOverlay(Actor akTarget, Bool Gender, String Area, String TextureToApply)
	Int SlotToUse = GetEmptySlot(akTarget, Gender, Area)
	If SlotToUse != -1
		ApplyOverlay(akTarget, Gender, Area, SlotToUse, TextureToApply)
	Else
		console("No slots available")
	EndIf
EndFunction

Function ApplyOverlay(Actor akTarget, Bool Gender, String Area, String OverlaySlot, String TextureToApply)
	;Float Alpha = GetCumSetAlpha(CumSet)
	float alpha = Utility.RandomFloat(0.75, 1.0)

	NiOverride.AddOverlays(akTarget)
	String Node = Area + " [ovl" + OverlaySlot + "]"
	NiOverride.AddNodeOverrideString(akTarget, Gender, Node, 9, 0, TextureToApply, true)
	NiOverride.AddNodeOverrideInt(akTarget, Gender, Node, 7, -1, 0, true)
    NiOverride.AddNodeOverrideInt(akTarget, Gender, Node, 0, -1, 0, true)
    NiOverride.AddNodeOverrideFloat(akTarget, Gender, Node, 8, -1, Alpha, true)
	NiOverride.AddNodeOverrideFloat(akTarget, Gender, Node, 2, -1, 0.0, true)
	NiOverride.AddNodeOverrideFloat(akTarget, Gender, Node, 3, -1, 0.0, true)
	
	NiOverride.ApplyNodeOverrides(akTarget)
EndFunction

Int Function GetEmptySlot(Actor akTarget, Bool Gender, String Area)
	Int i = 0
	Int NumSlots = GetNumSlots(Area)
	String TexPath
	Bool FirstPass = true

	While i < NumSlots
		TexPath = NiOverride.GetNodeOverrideString(akTarget, Gender, Area + " [ovl" + i + "]", 9, 0)
		console(TexPath)
		If TexPath == "" || TexPath == "actors\\character\\overlays\\default.dds"
			console("Slot " + i + " chosen for area: " + area)
			Return i
		EndIf
		i += 1
		If !FirstPass && i == NumSlots
			FirstPass = true
			i = 0
		EndIf
	EndWhile
	Return -1
EndFunction

Int Function GetNumSlots(String Area)
	If Area == "Body"
		Return NiOverride.GetNumBodyOverlays()
	ElseIf Area == "Face"
		Return NiOverride.GetNumFaceOverlays()
	ElseIf Area == "Hands"
		Return NiOverride.GetNumHandOverlays()
	Else
		Return NiOverride.GetNumFeetOverlays()
	EndIf
EndFunction

; https://freesound.org/people/j1987/sounds/106395/
; https://freesound.org/people/Intimidated/sounds/74511/

; https://freesound.org/people/Lukeo135/sounds/530617/
; https://freesound.org/people/nicklas3799/sounds/467348/