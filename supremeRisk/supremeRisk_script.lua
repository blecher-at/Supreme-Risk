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


    function basicSerialize (o)
      if type(o) == "number" then
        return tostring(o)
      else   -- assume it is a string
        return string.format("%q", o)
      end
    end

    function Xsave (name, value, saved)
	  local str = ""
      saved = saved or {}       -- initial value
      str = str..name.." = "
      if type(value) == "number" or type(value) == "string" then
        str = str..basicSerialize(value).."\n"
      elseif type(value) == "table" then
        if saved[value] then    -- value already saved?
          str = str..saved[value].."\n"  -- use its previous name
        else
          saved[value] = name   -- save name for next time
          str = str.."{}\n"     -- create a new table
          for k,v in value do      -- save its fields
            local fieldname = string.format("%s[%s]", name,
                                            basicSerialize(k))
            str = str..Xsave(fieldname, v, saved)
          end
        end
      else
        --error("cannot save a " .. type(value))
      end
	  return str
    end

	
function dump(tbl)
	LOG(Xsave("var",tbl,nil))
end

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
	
	-- NORTH AMERICA
	{	name='North States',
		pos = {x = 170, y = 375},
		owner = "ARMY_1",
		walls = nil
	},
	{	name='South States',
		pos = {x = 200, y = 410},
		owner = "ARMY_1",
		walls = nil
	},	
	{	name='Mexico',
		pos = {x = 139, y = 455},
		owner = "ARMY_1",
		walls = nil
	},	
	-- SOUTH AMERICA
	{	name='Argentinia',
		pos = {x = 290, y = 710},
		owner = "ARMY_1",
		walls = nil
	},
	{	name='Brasil',
		pos = {x = 350, y = 590},
		owner = "ARMY_1",
		walls = nil,
		startUnits = 7
	},	
	{	name='Venezuela',
		pos = {x = 250, y = 540},
		owner = "ARMY_1",
		walls = nil
	},	
	
	-- AFRICA
	{	name='West Africa',
		pos = {x = meter(8700), y = meter(10300)},
		owner = "ARMY_9",
		walls = circleWalls,
		startUnits = 6
	},
	{	name='Egypt',
		pos = {x = 530, y = 497},
		owner = "ARMY_9",
		walls = circleWalls
	},
	{	name='Congo',
		pos = {x = 522, y = 617},
		owner = "ARMY_1",
		walls = circleWalls
	},	
	{	name='South Africa',
		pos = {x = 560, y = 700},
		owner = "ARMY_1",
		walls = circleWalls
	},		
	{	name='East Africa',
		pos = {x = 584, y = 632},
		owner = "ARMY_1",
		walls = circleWalls
	},		
	{	name='Madagascar',
		pos = {x = 619, y = 684},
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
		sourceZone = Rect(0,0,350,500), -- redirect if into zone and 
		targetZone = Rect(700,0,1024,500), -- move order into this zone is issued
		name		='Alaska',
		teleporterSource = Pos(1,303),
		teleporterDest = Pos(1021,307),
    },
	{
		sourceZone = Rect(700,0,1024,500), -- redirect if into zone and 
		targetZone = Rect(1,1,300,500), -- move order into this zone is issued
		name		='kamc',
		teleporterSource = Pos(1022,305),
		teleporterDest = Pos(4,300),
    }
}
  
local player = nil;

function OnPopulate()
  LOG("OnPopulate ----------------------------------")
  
  -- prevent ACU warpin animation
  ScenarioInfo.Options['PrebuiltUnits'] = nil
  
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
  LOG("OnStart -------------------------------")
  LOG("Hello world")

  init()
--  initFactories()
  initStartUnits()
  
  initMainThread()
end

function init()
	for index,army in ListArmies() do
		LOG(index.." "..army.." is playing")
		
		#Building Restrictions
		ScenarioFramework.AddRestriction(index, categories.ALLUNITS)
		ScenarioFramework.RemoveRestriction(index, categories.uel0106)
	end
	

end

function initStartUnits()
	local yoffset = 6;
	for i,cdata in countries do
		-- Spawn one unit per country
		setAsPresident(cdata, nil)
		
		if cdata.startUnits then
			local ii = 0
			while ii < cdata.startUnits do
				CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x-2,cdata.pos.y+10,cdata.pos.y+yoffset, 0,0,0)
				ii = ii+1
			end
		end
--		local u = CreateUnitHPR('uel0106', cdata.owner, cdata.pos.x+2,cdata.pos.y+yoffset,cdata.pos.y+yoffset, 0,0,0)
		spawnCapital(cdata)
--		spawnFactory(cdata)
	end
		
local i = 0		
	-- debug spawn some units
	while i < 150 do
	unit = CreateUnitHPR('uel0106', "ARMY_1",50,0,300, 0,0,0)
	i = i+1
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
	u:SetMaxHealth(1)
	u:SetHealth(nil,1)
	u:SetRegenRate(1)
	u:SetIntelRadius('Vision', meter(baseSizeMeters*7))
	u:SetCustomName(name)
	cdata.factory = u
--	cdata.ownerId = armyId

	u:AddOnUnitBuiltCallback(function (factory, unit) 
		LOG(unit:GetEntityId())
		end
		, categories.MOBILE)


	u.OnStartBuildOriginal = u.OnStartBuild
	u.OnStartBuild = function(self, unitBeingBuilt, order)
		dump(unitBeingBuilt)
		LOG("Start building ")
		--IssueStop(self)
		self:OnStartBuildOriginal(unitBeingBuilt, order)
	end
		
	u:SetBuildTimeMultiplier(0.5)
--	u.UpdateConsumptionValues = function() end
	
end

function round(num)
	return math.floor(num + 0.5)
end

function createWall(army,x,y)
		local u = CreateUnitHPR('ueb5101', army, x,y,y, 0,0,0)
		u:SetCanBeKilled(false)
        u:CreateWreckageProp(1)
        u:Destroy()
--		u:EnableUnitIntel('Cloak')
--		u:DisableUnitIntel('Vision')
	

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
	ForkThread(maintenanceThread)
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

	local x = country.pos.x+1
	local y = country.pos.y+4
	if not unit then
		unit = CreateUnitHPR('uel0106', country.owner, x,0,y, 0,0,0)
		unit.isInitialPresident = true;
	end

	-- only alive units can be elected president
	if not unit:IsBeingBuilt() and not unit:IsDead() then
		LOG(country.name.." elected a new president")
		country.president = unit
		unit:SetCustomName("President of "..country.name)
		unit.isPresident = true

		-- stop unit from moving
		unit:SetImmobile(true)
		unit:SetUnSelectable(true)
--		unit:SetElevation(200)
--		local e = unit:GetElevation()
--		dump(e)
		
		unit:GetBlueprint().Economy.BuildCostMass = 10

--GetNavigator
--GetRallyPoint
--CanPathTo		
		
--		for index, o in moho.unit_methods do
--			LOG(index)
--		end
		
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

--	sourceZone = Rect(0,0,300,500), -- redirect if into zone and 
--		targetZone = Rect(700,0,1024,500), -- move order into this zone is issued
--		name		='Alaska',
--		teleporterSource = Pos(0,300),
--		teleporterDest = Pos(1024,310),
--    },

	for i, zone in teleportationZones do
		local units = GetUnitsInRect(zone.sourceZone)
		if units then
			for index,unit in units do
				-- teleport these units
				if not unit:IsDead() and not unit:IsBeingBuilt() and not unit.isPresident and unit:GetWeaponCount() > 0 
				then
--					local newPosition = unit:GetPosition();
--					local heading = unit:GetHeading();
--					dump(heading);
					--LOG("unit found")
					-- unit is ordered into the targetZone
					if isInside(zone.targetZone, unit:GetNavigator():GetGoalPos()) then
--						LOG("unit going to teleport beacon "..zone.name)
--						LOG("original Goal:: ")
--						dump(unit:GetNavigator():GetGoalPos())
						-- store original Waypoint
						unit.originalWaypoint = unit:GetNavigator():GetGoalPos()
					
						-- redirect to teleport zone
						--unit:GetNavigator():SetGoal(zone.teleporterSource)
						--IssueStop({unit})
						dump(unit:GetNavigator():GetStatus())
						unit:GetNavigator():SetGoal(zone.teleporterSource)
						--IssueMove({unit}, zone.teleporterSource)
					end
				end
			end
		end
		
		local unitsToTeleport = GetUnitsInRect(Pos2Rect(zone.teleporterSource, 12))
		if unitsToTeleport then
			for index,unit in unitsToTeleport do
				-- teleport these units
				if not unit:IsDead() and not unit:IsBeingBuilt() and unit:GetWeaponCount() > 0 and unit.originalWaypoint
				then
					--unit.targetRally = zone.targetRally
					--unit.targetRally = zone.targetRally
					-- teleport is for free ... shadow economyEvent function
					--unit.CreateEconomyEvent = function () end
					-- shadow teleport function to issue move afterwards
					--unit.InitiateTeleportThread = myInitiateTeleportThread
					local rp = 2
							
					local teleportPos = Pos(zone.teleporterDest[1]+math.random(-rp, rp),zone.teleporterDest[3]+math.random(-rp, rp))
--					local teleportPos = Pos(zone.teleporterDest[1],zone.teleporterDest[3]+zone.tpoffset)
--					local teleportPos = Pos(zone.teleporterDest[1],zone.teleporterDest[3])

					LOG("Warping unit from Zone "..zone.name.." to "..Xsave('aaa',teleportPos))
--					if unit:CanPathTo(teleportPos) then 

					--fix ferry bug with transports?
					local cs = 0;

			        if EntityCategoryContains(categories.TRANSPORTATION, unit) then
			                local cargo = unit:GetCargo()
			                if table.getn(cargo) > 0 then
			                    for k, v in cargo do
									LOG(v)
			                    end
			                end
							
						LOG("cargo size pre teleport: "..table.getn(cargo))
						Warp(unit, teleportPos, unit:GetOrientation())
						WaitSeconds(0.2)
		                local cargo = unit:GetCargo()
						LOG("cargo size post teleport: "..table.getn(cargo))
					else
						Warp(unit, teleportPos, unit:GetOrientation())
						WaitSeconds(0.2)
					
			        end

						-- Move to Original Waypoint
						unit:GetNavigator():SetGoal(unit.originalWaypoint)					
						IssueMove({unit}, unit.originalWaypoint)
						unit.wayPointAfterTeleport = unit.originalWaypoint
						unit.originalWaypoint = nil;
						unit.lastTeleportZoneUsed = zone;
						unit.teleporterStaleCounter = 0;
--					end
					--unit:OnTeleportUnit(unit, newPosition,{0,0,0,1})
					--unit.CreateEconomyEvent = ee -- dont reset, we are async
				end
			end
		end
		
	end
end

function checkTeleportationZonesPFWorkaround()
	-- Help the bugged pathfinding a little...
	for i, zone in teleportationZones do
		local staleUnits = GetUnitsInRect(Pos2Rect(zone.teleporterDest, 5))
		if staleUnits then
			for index,unit in staleUnits do
				if unit.wayPointAfterTeleport and unit.lastTeleportZoneUsed == zone and unit.teleporterStaleCounter < 50 then
						-- Move to Original Waypoint
						unit:GetNavigator():SetGoal(unit.wayPointAfterTeleport)					
						IssueMove({unit}, unit.wayPointAfterTeleport)
						unit.teleporterStaleCounter = unit.teleporterStaleCounter+1
						WaitSeconds(0)
						LOG("Unit path reassigned the "..unit.teleporterStaleCounter..". time")
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
				
					local weapon = unit:GetWeapon(1)
					local h = 10
					unit:SetMaxHealth(h)
					unit:SetHealth(nil, h)
--				LOG(unit:GetBlueprint())
					if(armycounters[unit:GetArmy()]) then
						armycounters[unit:GetArmy()] = armycounters[unit:GetArmy()] +1
					else
						armycounters[unit:GetArmy()] = 1;
					end
					
					
					if(getArmyName(unit) == cdata.owner) then
						-- own unit
						weapon:ChangeRateOfFire(1)
--						weapon:SetTurretYawSpeed(300)
--						weapon:SetTurretPitchSpeed(300)
						weapon:ChangeMaxRadius(meter(baseSizeMeters)*baseSizeInner)
						weapon:SetFiringRandomness(1.0)
					
						if cdata.president != unit then
							--unit:SetCustomName("") --Citizen of "..cdata.name)
						end
						
						if not presidentIsAlive(cdata) then
							setAsPresident(cdata, unit)
						end
					else
						-- enemy unit
						weapon:SetFiringRandomness(1.4)
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

function maintenanceThread()
	while true do
		checkTeleportationZonesPFWorkaround()
		WaitSeconds(5)
	end
end

function garbage__()

		if unit.originalUpdateMovementEffectsOnMotionEventChange == nil then
			unit.originalUpdateMovementEffectsOnMotionEventChange = unit.UpdateMovementEffectsOnMotionEventChange
			unit.UpdateMovementEffectsOnMotionEventChange = function(self, new, old)
				self:originalUpdateMovementEffectsOnMotionEventChange(new,old)
				LOG("New Move Command")
				local navi = self:GetNavigator()
				dump(navi:GetGoalPos())
				
				
				if navi.SetGoalOriginal == nil then
					navi.SetGoalOriginal = navi.SetGoal
					navi.myUnit = self
					navi.SetGoal = function (self2, position)
						self2:SetGoalOriginal(position)
						LOG("SETGOAL")
					end
				end
			end
--			dump(unit:GetRallyPoint())
		end
end


function isInside(zone, pos)
	if  pos[1] <= zone.x1 and pos[1] >= zone.x0 
	and pos[3] <= zone.y1 and pos[3] >= zone.y0 then
		return true
	else
		return false
	end
end

function Pos2Rect(pos, radius)
	return Rect(pos[1]-radius, pos[3]-radius, pos[1]+radius, pos[3]+radius)
end
