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

function Pos(x,y)
	local p = {}
	p[1] = x
	p[3] = y
	p[2] = 0
	return p
end

  
function circleWalls(cdata)
	local x = cdata.pos.x
	local y = cdata.pos.y

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


local tblGroup = nil;

local countries = {
	{	name='Iceland',
		pos = {
			x = 407, 
			y = 330
		},
		owner = "ARMY_1",
		walls = nil;
	},
	{	name='Alaska',
		pos = {
			x = 100, 
			y = 285
		},
		owner = "ARMY_1",
		walls = circleWalls;
	},	
	{	name='West Africa',
		pos = {
			x = meter(8700), 
			y = meter(10300)
		},
		owner = "ARMY_1",
		walls = circleWalls
	},
	
		{	name='Kamchatka',
		pos = {
			x = 920,			
			y = 305
		},
		owner = "ARMY_1",
		walls = circleWalls
	},
  {
		name='China',
		pos = {
			x = meter(4100), 
			y = meter(2800)
		},
		owner = "ARMY_9",
		walls = circleWalls
  }
  }

local teleportationZones = {
	{
		name		='Alaska',
		pos			= Rect(0,0,60,500),
		target 		= Pos(1000,310), 
		targetRally = Pos(960,315),
		orientationRequirement = function(orientation) 
			if orientation[2] <0 then 
				return true
			else
				return false
			end
		end
    },
	{
		name		='kamc',
		pos			= Rect(970,0,1024,500),
		target 		= Pos(30,300), 
		targetRally = Pos(70,285),
		orientationRequirement = function(orientation) 
			if orientation[2] >0 then return true
			else return false
			end
		end
    }
}
  
local player = nil;

function OnPopulate()
  LOG("AAA")
  tblGroup = ScenarioUtils.InitializeArmies()
  for i,acu in tblGroup do
	LOG(i.." ")
	for i2,acu2 in acu do
		LOG(i2)
	end
  end
  
  ScenarioFramework.SetPlayableArea('AREA_1' , false)
  
  -- Set Camera to show full Map
  local Camera = import('/lua/SimCamera.lua').SimCamera
  local cam = Camera("WorldCamera")
--  cam:MoveTo(ScenarioUtils.AreaToRect('AREA_1'))
	cam:SetZoom(2000,0)

	for a, ccc in ScenarioUtils.AreaToRect('AREA_1') do LOG(a.." "..ccc) end

  LOG("ONPOPULATE END")
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
		setAsPresident(cdata, nil)
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x-2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x+2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
		spawnCapital(cdata)
--		spawnFactory(cdata)
	end
			
end
function spawnCapital(cdata)
	cdata.factoryOwnershipChanged = false
	spawnFactory(cdata)
	
	if cdata.walls != nil then
		cdata:walls(cdata)
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
	

	
end

function round(num)
	return math.floor(num + 0.5)
end

function createWall(army,x,y)
		local u = CreateUnitHPR('ueb5101', army, x,y,y, 0,0,0)
		u:SetCanBeKilled(true)
        u:CreateWreckageProp(0)
        u:Destroy()
	

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

	local x = country.pos.x-2
	local y = country.pos.y+5
	if not unit then
		unit = CreateUnitHPR('uel0106', country.owner, x,0,y, 0,0,0)
		unit.isInitialPresident = true;
	end

	-- only alive units can be elected president
	if not unit:IsBeingBuilt() and not unit:IsDead() then
		LOG(country.name.." elected a new president")
		country.president = unit
		unit:SetCustomName("President of "..country.name)

		-- stop unit from moving
		unit:SetImmobile(true)
		
		-- only warp if not initial
		if not unit.isInitialPresident then
--	unit:SetSpeedMult(0)
--	unit.OnMotionHorzEventChange = function() end
--	unit.OnMotionVertEventChange = function() end
--	unit.OnMotionTurnEventChange = function() end
--	unit.UpdateMovementEffectsOnMotionEventChange = function() end

--		for a, ccc in unit:GetOrientation() do LOG(a.." "..ccc) end
--		for a, ccc in unit:GetPosition() do LOG(a.." "..ccc) end
--		LOG(unit:GetOrientation())
		
		unit.TeleportDrain = nil
		unit.SetImmobile = function() end -- prevent the following function to make the unit moveable again.
		unit.InitiateTeleportThread = myInitiateTeleportThread
		unit:OnTeleportUnit(unit, {x,0,y},{0,0,0,1})
--		Warp(unit,{country.pos.x,0,country.pos.y+6,0},{0,0,0,1})
		end
	end
end


function myInitiateTeleportThread(self, teleporter, location, orientation)
        self.UnitBeingTeleported = self
        self:SetImmobile(true)

        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        # create teleport charge effect
        self:PlayTeleportChargeEffects()
        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        WaitSeconds( 0.1 )
        #Teleport Sound
        self:SetWorkProgress(0.0)
        Warp(self, location, orientation)
        self:PlayTeleportInEffects()
        WaitSeconds( 0.1 ) # Perform cooldown Teleportation FX here
    #Landing Sound
    #LOG('DROP')
    self:StopUnitAmbientSound('TeleportLoop')
    self:PlayUnitSound('TeleportEnd')
    self:SetImmobile(false)
    self.UnitBeingTeleported = nil
    self.TeleportThread = nil

	LOG("Teleport done")
	if self.targetRally then
		IssueMove( {self}, self.targetRally )
	end
end

function checkTeleportationZones()
	for i, zone in teleportationZones do
		local units = GetUnitsInRect(zone.pos)
		if units then
			for index,unit in units do
				-- teleport these units
				if not unit:IsDead() and not unit:IsBeingBuilt() and unit:GetWeaponCount() > 0 
					and zone.orientationRequirement(unit:GetOrientation()) 
				then
			
					local newPosition = unit:GetPosition();

					newPosition[1] = zone.target[1];
					newPosition[3] = zone.target[3];
					
					unit.targetRally = zone.targetRally
					-- teleport is for free ... shadow economyEvent function
					unit.CreateEconomyEvent = function () end
					
					-- shadow teleport function to issue move afterwards
					unit.InitiateTeleportThread = myInitiateTeleportThread
					unit:OnTeleportUnit(unit, newPosition,{0,0,0,1})
					--unit.CreateEconomyEvent = ee -- dont reset, we are async
				end
			end
		end
	end
end

function checkCountryOwnership()
	local baseSizeInner = 0.9
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
				if not unit:IsDead() and not unit:IsBeingBuilt() and unit:GetWeaponCount() > 0 then
				
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
		checkTeleportationZones()
		WaitSeconds(1)
	end
end

