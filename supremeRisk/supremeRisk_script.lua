--[[
Don't edit or remove this comment block! It is used by the editor to store information since i'm too lazy to write a good LUA parser... -Haz
SETTINGS
RestrictedEnhancements=ResourceAllocation,DamageStablization,AdvancedEngineering,T3Engineering,HeavyAntiMatterCannon,LeftPod,RightPod,Shield,ShieldGeneratorField,TacticalMissile,TacticalNukeMissile,Teleporter
RestrictedCategories=EXPERIMENTAL,MASSFABRICATION
END
--]]

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

--scenario utilities
local Utilities = import('/lua/utilities.lua')

--interface utilities
local UIUtil = import('/lua/ui/uiutil.lua')
local gameParent = import('/lua/ui/game/gamemain.lua').GetGameParent()

local executing = false
local beatTime = 5
local baseSizeMeters = 400;

function meter(m)
	return m*0.0512
end

local countries = {
    {
		name='West Africa',
		pos = {
			x = meter(8700), 
			y = meter(10300)
		},
		owner = "ARMY_1"
  },
  {
		name='China',
		pos = {
			x = meter(4100), 
			y = meter(2800)
		},
		owner = "ARMY_9"
  }
  }
  
  


local player = nil;

function OnPopulate()
  LOG("AAA")
  ScenarioUtils.InitializeArmies()
  ScenarioFramework.SetPlayableArea('AREA_1' , false)
end

function OnStart(self)
--	PrintText("KAKAKAAK",20,'FFFFFFFF',20,'center')
  LOG("AAA")
  LOG("Hello world")

  init()
--  initFactories()
  initStartUnits()
  
  initMainThread()
end

function init()
	for index,army in ListArmies() do
		LOG(index.." "..army.." is playing")
		
	end
end

function initStartUnits()
	local yoffset = 6;
	for i,cdata in countries do
		-- Spawn one unit per country
		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x-2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x+2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
--		spawnFactory(cdata)
	end
			
end

function spawnFactory(cdata)
	local x = cdata.pos.x
	local y = cdata.pos.y
	local name = cdata.name
	local army = cdata.owner
	local u = CreateUnitHPR( 'ueb0101', army, x,y,y, 0,0,0)

	u.CreateWreckage = function() end

	u:SetAllWeaponsEnabled(false)		
	u:SetCanBeKilled(true)
	u:SetDoNotTarget(true)
	u:SetMaxHealth(1000)
	u:SetHealth(nil,1000)
	u:SetRegenRate(1)
	u:SetIntelRadius('Vision', meter(baseSizeMeters*3))
	u:SetCustomName(name)
	cdata.factory = u
--	cdata.ownerId = armyId
	
	local wd = baseSizeMeters;
	local wallDistance = 1;
	local yo = 4;
	local xo = meter(wd)
	while yo+wallDistance < xo do
		xo = (math.sqrt(meter(wd)*meter(wd)-yo*yo))
		createWall4("ARMY_9",x,y,xo,yo)
		yo = yo+wallDistance
	end
	
	xo = 4;
	while xo < yo do
		yo = (math.sqrt(meter(wd)*meter(wd)-xo*xo))
		createWall4("ARMY_9",x,y,xo,yo)
		xo = xo+wallDistance
	end
	
end

function round(num)
	return math.floor(num + 0.5)
end

function createWall(army,x,y)
		local u = CreateUnitHPR('ueb5101', army, x,y,y, 0,0,0)
		u:SetCanBeKilled(true)
	

end


function createWall4(army,x,y,ox,oy)
	createWall(army,x+ox,y+oy)
	createWall(army,x-ox,y+oy)
	createWall(army,x+ox,y-oy)
	createWall(army,x-ox,y-oy)
end

function initMainThread()
	ForkThread(mainThread)
	ForkThread(jobsThread)
end

function getArmyName(unit)
	local unitArmy = unit
	if unit.GetArmy then
		unitArmy = unit:GetArmy()
	end
	
	return ListArmies()[unitArmy]
end

function presidentIsAlive(country)
	if country.president == nil or country.president:IsDead() == true then
		return false
	else
		return true
	end
end

function setAsPresident(country, unit)
	LOG(country.name.." elected a new president")
	country.president = unit
	unit:SetCustomName("President of "..country.name)

	-- stop unit from moving
	unit:SetSpeedMult(0)
	unit.OnMotionHorzEventChange = function() end
	unit.OnMotionVertEventChange = function() end
	unit.OnMotionTurnEventChange = function() end
	unit.UpdateMovementEffectsOnMotionEventChange = function() end
	
end

function checkCountryOwnership()
	local baseSizeInner = 0.6
	for i,cdata in countries do
		rect = {x0 = cdata.pos.x - meter(baseSizeMeters)*baseSizeInner,
				x1 = cdata.pos.x + meter(baseSizeMeters)*baseSizeInner,
				y0 = cdata.pos.y - meter(baseSizeMeters)*baseSizeInner,
				y1 = cdata.pos.y + meter(baseSizeMeters)*baseSizeInner
				}
				
		local units = GetUnitsInRect(rect)
		
		local armycounters = {}
		if units then
			for index,unit in units do
				if not unit:IsDead() and unit:GetWeaponCount() > 0 then
				
--				LOG(unit:GetBlueprint())
					if(armycounters[unit:GetArmy()]) then
						armycounters[unit:GetArmy()] = armycounters[unit:GetArmy()] +1
					else
						armycounters[unit:GetArmy()] = 1;
					end
					
					
					if(getArmyName(unit) == cdata.owner) then
						if cdata.president != unit then
							--unit:SetCustomName("") --Citizen of "..cdata.name)
						end
						
						if not presidentIsAlive(cdata) then
							setAsPresident(cdata, unit)
						end
					else
						--unit:SetCustomName("Liberator of "..cdata.name)
					end
				end
			end
		end
	
		local enemyUnits = 0;
		local enemyArmy = nil;
		local friendlyUnits = 0;
		for index, counter in armycounters do
			--LOG("player "..index.." "..getArmyName(index)..": "..counter.." found in "..cdata.name.." ("..cdata.owner..")");
			if getArmyName(index) == cdata.owner then
				friendlyUnits = counter
			else
				enemyUnits = enemyUnits +counter
				enemyArmy = getArmyName(index)
			end
	    end
		if enemyUnits > 0 then
			setFactoryName(cdata,cdata.name..": "..friendlyUnits.." attacked by "..enemyUnits)
		else
			setFactoryName(cdata,cdata.name..": "..friendlyUnits)
		
		end

		if friendlyUnits == 0 and enemyUnits > 0 then
			cdata.owner = enemyArmy
			cdata.factoryOwnershipChanged = true;
		end
		if friendlyUnits == 0 and enemyUnits == 0 and cdata.owner != "ARMY_9" then
			cdata.owner = "ARMY_9"
			cdata.factoryOwnershipChanged = true;
		
		end
	end

end

function setFactoryName(country, text)
--	if country.factory.isDead and not country.factory:isDead() then 
		if country.factory != nil and not country.factory:IsDead() then
			country.factory:SetCustomName(text)
			end
--	end

end

function reassignFactories()
	for i,c in countries do
		if c.factoryOwnershipChanged == true or c.factoryOwnershipChanged == nil or c.factory:IsDead() then
			if c.factory != nil then
				local f = c.factory
				c.factory = nil;
				f:Kill()
				WaitSeconds(7)
			end
			spawnFactory(c)
			c.factoryOwnershipChanged = false
		end
	end
end

function mainThread()
	while true do
		checkCountryOwnership()
		WaitSeconds(1)
	end
end

function jobsThread()
	while true do
		reassignFactories()
		WaitSeconds(1)
	end
end