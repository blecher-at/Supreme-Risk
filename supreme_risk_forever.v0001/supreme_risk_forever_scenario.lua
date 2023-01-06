version = 3 -- Lua Version. Dont touch this
ScenarioInfo = {
    name = "Supreme Risk Forever",
    description = "<LOC supremeRisk_Description>Supreme Risk is a SupCom minigame enabling risks rules for fights over Earths continents. !! This version is compatible with FAF from 2023",
    preview = '',
    map_version = 1,
    type = 'skirmish',
    starts = true,
    size = {1024, 1024},
    reclaim = {55323.27, 411310.9},
    map = '/maps/supreme_risk_forever.v0001/supreme_risk_forever.scmap',
    save = '/maps/supreme_risk_forever.v0001/supreme_risk_forever_save.lua',
    script = '/maps/supreme_risk_forever.v0001/supreme_risk_forever_script.lua',
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
