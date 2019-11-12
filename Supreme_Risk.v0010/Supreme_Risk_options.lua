options = {
    {
		default = 3,
        label = "Supreme Risk: Round Length",
        help = "",
        key = "SRRoundLength",
        pref = "SRRoundLength",
        values = {
			{
              text = "20 Seconds",
				help = "",
				key = 20,
			},
			{
              text = "30 Seconds",
				help = "",
              key = 30,
			},
			{
              text = "40 Seconds",
        help = "",
              key = 40,
			},
			{
              text = "50 Seconds",
        help = "",
              key = 50,
			},
			{
              text = "60 Seconds",
        help = "",
              key = 60,
			},
       },
    },
    {
		default = 2,
        label = "Supreme Risk: Unit Movement",
        help = "",
        key = "SRUnitMovement",
        pref = "SRUnitMovement",
        values = {
			{
              text = "Free",
              help = "Units can move freely from territory to territory with not restrictions.",
              key = "free",
			},
			{
              text = "Aggressive (Risk default)",
              help = "Units can move freely from a territory the player owns to an enemy territory. Units can only move to one own territory per round.",
              key = "agro",
			},
			{
              text = "Limited",
              help = "Units can move from one territory to the next per round. If a territory has been liberated, units will stay there until the next round.",
              key = "limit",
			}
		}
    },
    {
		default = 1,
        label = "Supreme Risk: Reinforcing Mode",
        help = "",
        key = "SRBuildMode",
        pref = "SRBuildMode",
        values = {
            {
              text = "Unbuilt units expire",
              help = "Build units manually in factories. Units that are not built in the current round expire.",
              key = "expire",
           },
            {
              text = "Unbuilt units don't expire",
              help = "Build units manually in factories. Units that are not built in the current round can be built later",
              key = "keep",
           },
       },
    },
   
} 