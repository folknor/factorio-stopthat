local d = require("defines")
local _robo = "roboport-equipment"

local simply = setmetatable({}, {
	__index = function(self, id)
		local v = settings.get_player_settings(game.players[id])[d.sSimplyKey].value
		rawset(self, id, v)
		return v
	end
})
local disableAt = setmetatable({}, {
	__index = function(self, id)
		local percent = (settings.get_player_settings(game.players[id])[d.sSpeedKey].value / 100)
		local robotSpeed = d.defaultSpeed * game.players[id].force.worker_robots_speed_modifier
		local v = robotSpeed * percent
		rawset(self, id, v)
		return v
	end
})
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if not event or not event.setting then return end
	if event.setting == d.sSimplyKey then
		simply[event.player_index] = nil
	elseif event.setting == d.sSpeedKey then
		disableAt[event.player_index] = nil
	end
end)
script.on_event(defines.events.on_research_finished, function() for k in pairs(disableAt) do disableAt[k] = nil end end)

local fakeItems = setmetatable({}, {
	__index = function(self, k)
		local v = d._NAME:format(k)
		if not game.equipment_prototypes[v] then v = false end
		rawset(self, k, v)
		return v
	end
})

-- Do the table-churn dance \o/ \o/ \o/
-- I don't know how to dance.
local function swapIn(g, old, new)
	if not new then return end
	local pos = old.position
	g.take({ position = pos })
	local putted = g.put({
		name = new,
		position = pos
	})
	if putted then putted.energy = putted.max_energy end
end

local function restore(g)
	for _, eq in next, g.equipment do
		if eq.type == _robo and eq.prototype.order == d._ORDER then
			swapIn(g, eq, eq.prototype.take_result.name)
		end
	end
end

local function nuke(g)
	for _, eq in next, g.equipment do
		if eq.type == _robo and eq.prototype.order ~= d._ORDER then
			swapIn(g, eq, fakeItems[eq.name])
		end
	end
end

local function getSpeed(e) return e.type == "car" and e.speed or e.train.speed end

-- Yes, yes, if we have the simply-setting toggled,
-- things are disabled+enabled immediately upon entering a vehicle. I don't want to fix it.
local function tick(event)
	if event.tick % 60 == 0 then
		for id, p in pairs(game.players) do
			if p.valid and p.connected and p.character and p.character.grid then
				if global.state[id] then
					if not p.vehicle or (getSpeed(p.vehicle) < (disableAt[id] + 0.05) and not simply[id]) or getSpeed(p.vehicle) == 0 then
						restore(p.character.grid)
						global.state[id] = nil
					end
				else
					if p.vehicle and (getSpeed(p.vehicle) > disableAt[id] or simply[id]) and getSpeed(p.vehicle) ~= 0 then
						nuke(p.character.grid)
						global.state[id] = true
					end
				end
			end
		end
	end
end
script.on_event(defines.events.on_tick, tick)

-- When the vehicle is mined, we restore the roboports in ontick
local function driving(event)
	if not event or not event.player_index or not simply[event.player_index] then return end
	local p = game.players[event.player_index]
	if p and p.valid and p.character and p.character.grid then
		if global.state[event.player_index] then
			if not p.vehicle then
				restore(p.character.grid)
				global.state[event.player_index] = nil
			end
		else
			if p.vehicle then
				nuke(p.character.grid)
				global.state[event.player_index] = true
			end
		end
	end
end
script.on_event(defines.events.on_player_driving_changed_state, driving)

script.on_init(function()
	-- key: player index, value: boolean
	if not global.state then global.state = {} end
end)


