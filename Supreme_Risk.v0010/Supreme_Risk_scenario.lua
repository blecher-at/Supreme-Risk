version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Supreme Risk (FAF)",
    description = "<LOC supremeRisk_Description>Supreme Risk is a SupCom minigame enabling risks rules for fights over Earths continents. !! This version is compatible with FAF",
    preview = '',
    map_version = 10,
    type = 'skirmish',
    starts = true,
    size = {1024, 1024},
    map = '/maps/Supreme_Risk.v0010/Supreme_Risk.scmap',
    save = '/maps/Supreme_Risk.v0010/Supreme_Risk_save.lua',
    script = '/maps/Supreme_Risk.v0010/Supreme_Risk_script.lua',
    norushradius = 2000,
    Configurations = {
        ['standard'] = {
            teams = {
                {
                    name = 'FFA',
                    armies = {'ARMY_1', 'ARMY_2', 'ARMY_3', 'ARMY_4', 'ARMY_5', 'ARMY_6'}
                },
            },
            customprops = {
                ['ExtraArmies'] = STRING( 'ARMY_7 ARMY_8' ),
            },
        },
    },
}
