local d = require("defines")
_G.data:extend({
	{
		type = "bool-setting",
		name = d.sSimplyKey,
		setting_type = "runtime-per-user",
		default_value = false,
	},
	{
		type = "int-setting",
		name = d.sSpeedKey,
		setting_type = "runtime-per-user",
		default_value = 130,
		minimum_value = 10,
		maximum_value = 900,
	}
})
