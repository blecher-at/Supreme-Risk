version = 3
ScenarioInfo = {
  name = 'Supreme Risk (SupCom)',
  type = 'skirmish',
  description = '<LOC supremeRisk_Description>Supreme Risk is a SupCom minigame enabling risks rules for fights over Earths continents. !! This version is for stock SupCom and does not work with FAF',
  starts = true,
  preview = '',
  size = {1024, 1024},
  map = '/maps/Supreme_Risk/Supreme_Risk.scmap',
  save = '/maps/Supreme_Risk/Supreme_Risk_save.lua',
  script = '/maps/Supreme_Risk/Supreme_Risk_script.lua',
  norushradius = 2000,
  norushoffsetX_ARMY_1=0,
	norushoffsetY_ARMY_1=0,
	norushoffsetX_ARMY_2=0,
	norushoffsetY_ARMY_2=0,
	norushoffsetX_ARMY_3=0,
	norushoffsetY_ARMY_3=0,
	norushoffsetX_ARMY_4=0,
	norushoffsetY_ARMY_4=0,
	norushoffsetX_ARMY_5=0,
	norushoffsetY_ARMY_5=0,
	norushoffsetX_ARMY_6=0,
	norushoffsetY_ARMY_6=0,


  Configurations = {
    ['standard'] = {
      teams = {
        { name = 'FFA', armies = {'ARMY_1','ARMY_2','ARMY_3','ARMY_4','ARMY_5','ARMY_6',} },
      },
      customprops = {
        ['ExtraArmies'] = STRING( 'ARMY_9 NEUTRAL_CIVILIAN' ),
      },
    },
  }}
