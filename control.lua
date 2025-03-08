local d = require("defines")
local _robo = "roboport-equipment"

---@class storage
---@field state { [number]: boolean }

-- local always = setmetatable({}, {
-- 	__index = function(self, id)
-- 		local v = settings.get_player_settings(game.players[id])[d.sAlwaysKey].value
-- 		rawset(self, id, v)
-- 		return v
-- 	end,
-- })

local simply = setmetatable({}, {
	__index = function(self, id)
		local v = settings.get_player_settings(game.players[id])[d.sSimplyKey].value
		rawset(self, id, v)
		return v
	end,
})

local disableAt = setmetatable({}, {
	__index = function(self, id)
		local percent = (settings.get_player_settings(game.players[id])[d.sSpeedKey].value / 100)
		local robotSpeed = d.defaultSpeed * game.players[id].force.worker_robots_speed_modifier
		local v = robotSpeed * percent
		rawset(self, id, v)
		return v
	end,
})

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	---@cast event OnRuntimeModSettingChanged
	if not event or not event.setting then return end
	if event.setting == d.sSimplyKey then
		simply[event.player_index] = nil
	elseif event.setting == d.sSpeedKey then
		disableAt[event.player_index] = nil
		-- elseif event.setting == d.sAlwaysKey then
		-- 	always[event.player_index] = nil
	end
end)
script.on_event(defines.events.on_research_finished, function() for k in pairs(disableAt) do disableAt[k] = nil end end)

local fakeItems = setmetatable({}, {
	__index = function(self, k)
		---@type string|boolean
		local v = d._NAME:format(k)
		if not prototypes.equipment[v] then v = false end
		rawset(self, k, v)
		return v
	end,
})

-- Do the table-churn dance \o/ \o/ \o/
-- I don't know how to dance.
---@param g LuaEquipmentGrid
---@param old LuaEquipment
---@param new string
local function swapIn(g, old, new)
	if not new then return end
	local pos = old.position
	local q = old.quality
	local removed = g.take({ position = pos, })
	if removed then
		local putted = g.put({
			name = new,
			position = pos,
			quality = q,
		})
		if putted then putted.energy = putted.max_energy end
	end
end

---@param g LuaEquipmentGrid
local function restore(g)
	for _, eq in next, g.equipment do
		if eq.type == _robo and eq.prototype.order == d._ORDER then
			swapIn(g, eq, eq.prototype.take_result.name)
		end
	end
end

---@param g LuaEquipmentGrid
local function nuke(g)
	for _, eq in next, g.equipment do
		if eq.type == _robo and eq.prototype.order ~= d._ORDER then
			swapIn(g, eq, fakeItems[eq.name])
		end
	end
end

---@param e LuaEntity
---@return number
local function getSpeed(e) return (e.train and e.train.speed) or e.speed end

-- Yes, yes, if we have the simply-setting toggled,
-- things are disabled+enabled immediately upon entering a vehicle. I don't want to fix it.
local function tick()
	for id, p in pairs(game.players) do
		if p.valid and p.connected and p.character and p.character.grid then
			if storage.state[id] then
				if
					not p.vehicle or
					(getSpeed(p.vehicle) < (disableAt[id] + 0.05) and not simply[id]) or
					getSpeed(p.vehicle) == 0
				then
					restore(p.character.grid)
					storage.state[id] = nil
				end
			else
				if
					p.vehicle and
					(getSpeed(p.vehicle) > disableAt[id] or simply[id]) and
					getSpeed(p.vehicle) ~= 0
				then
					nuke(p.character.grid)
					storage.state[id] = true
				end
			end
		end
	end
end
script.on_nth_tick(60, tick)

-- When the vehicle is mined or destroyed, we restore the roboports in ontick
local function driving(event)
	---@cast event OnPlayerDrivingChangedState
	if not event or not event.player_index or not simply[event.player_index] then return end
	local p = game.players[event.player_index]
	if p and p.valid and p.character and p.character.grid then
		if storage.state[event.player_index] then
			if not p.vehicle then
				restore(p.character.grid)
				storage.state[event.player_index] = nil
			end
		else
			if p.vehicle then
				nuke(p.character.grid)
				storage.state[event.player_index] = true
			end
		end
	end
end
script.on_event(defines.events.on_player_driving_changed_state, driving)

script.on_init(function()
	-- key: player index, value: boolean
	if not storage.state then
		---@type { [number]: boolean }
		storage.state = {}
	end
end)
