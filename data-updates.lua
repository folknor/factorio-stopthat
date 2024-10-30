do
	local data = _G.data
	local sprite = {
		filename = "__folk-stopthat__/eq.png",
		width = 64,
		height = 64,
		priority = "medium"
	}
	local d = require("defines")

	-- If it wasn't for the fact that when we make the fake equipment a non-roboport one,
	-- expelled robots will fly towards alternative logistic networks, we would make the
	-- fake items "solar-panel-equipment". But since they do, we need to create fake
	-- "roboport-equipment"
	local add = {}

	for name, eq in pairs(data.raw["roboport-equipment"]) do
		if type(eq.take_result) == "string" then
			local cc = table.deepcopy(eq)
			cc.name = d._NAME:format(name)
			cc.localised_name = { "lulzstopthat.robotbbq", { "equipment-name." .. eq.name } }
			cc.sprite = sprite
			cc.energy_consumption = "0W"
			cc.robot_limit = 0
			cc.spawn_and_station_height = 0
			cc.construction_radius = 0
			cc.order = d._ORDER

			local it = table.deepcopy(data.raw.item[cc.take_result])
			it.name = cc.name
			it.hidden = true
			it.placed_as_equipment_result = name

			table.insert(add, cc)
			table.insert(add, it)
		end
	end
	data:extend(add)
end
