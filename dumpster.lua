local Config = _ENV.Config.Dumpster

-- missing config?
if not Config then return end

local dumpsters = Config.dumpsters
local bins = Config.bins

-- everything is disabled?
if not Config.storage and not Config.canHide then
	exports["qb-target"]:RemoveTargetModel(dumpsters)
	exports["qb-target"]:RemoveTargetModel(bins)
	return
end

local QBCore = exports["qb-core"]:GetCoreObject()
local LoadAnimDict = QBCore.Functions.RequestAnimDict
local canInteract, playerPed

-------------------------------------------------------------------------------
-- Dumpster Storage

if Config.storage then
	local floor = math.floor
	local weight_dumpster = {maxweight = Config.weight, slots = Config.slots}
	local weight_trash = {maxweight = Config.weight * 0.5, slots = Config.slots * 0.5}

	local fmt_dumpster = "Dumpster \124 %s X %s"
	local fmt_trash = "Trash \124 %s X %s"

	local function Round(num, decimals)
		local mult = 10 ^ (decimals or 0)
		return floor(num * mult + 0.5) / mult
	end

	-- will be overriden if hiding is enabled
	canInteract = function()
		playerPed = PlayerPedId()
		return (not IsPedDeadOrDying(playerPed) and not LocalPlayer.state.handsUp)
	end

	-- event: dumpster:open
	RegisterNetEvent("dumpster:open", function(data)
		-- prepare target, id and weight
		local targets = data and data.target
		if not targets then return end

		-- defaults
		local fmt = fmt_dumpster
		local weight = weight_dumpster
		local radius = 2.2

		-- in case of trash bins
		if targets == "bins" then
			fmt = fmt_trash
			weight = weight_trash
			radius = 1.0
		end

		-- replace targets with the table
		targets = Config[targets]
		if not targets then return end

		playerPed = PlayerPedId()
		local pcoords = GetEntityCoords(playerPed)

		for i = 1, #targets do
			local object = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, radius, targets[i], false, false, false)
			if object then
				local ocoords = GetEntityCoords(object)
				local dist = #(pcoords - ocoords)
				if dist < 2 then
					LoadAnimDict("amb@prop_human_bum_bin@idle_b")
                    TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 6.0, -6.0, -1, 49, 0, 0, 0, 0)

					local x = Round(ocoords.x < 0 and -ocoords.x or ocoords.x)
					local y = Round(ocoords.y < 0 and -ocoords.y or ocoords.y)
					local id = fmt:format(x, y)
					TriggerServerEvent("inventory:server:OpenInventory", "stash", id, weight)
					TriggerEvent("inventory:client:SetCurrentStash", id)

					Wait(1000)
                    StopAnimTask(playerPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 1.0)
					break
				end
			end
		end
	end)
end

-------------------------------------------------------------------------------
-- Hide in trash

if Config.canHide then
	local DrawText3D = QBCore.Functions.DrawText3D
	local canHide, inTrash = true, false
	local hideSpot = nil

	-- override can interact
	canInteract = function()
		playerPed = PlayerPedId()
		if LocalPlayer.state.handsUp or IsPedDeadOrDying(playerPed) or IsPedFatallyInjured(playerPed) then
			return false
		end
		return (canHide and not inTrash)
	end

	local function ExitDumpster(ped)
		if not hideSpot then return end
		SetEntityCollision(ped, true, true)
		inTrash = false
		canHide = true
		DetachEntity(ped, true, true)
		SetEntityVisible(ped, true, false)
		ClearPedTasks(ped)

		local forward = GetEntityForwardVector(hideSpot)
		local coords = GetEntityCoords(ped)
		local x, y, z = table.unpack(coords - forward * 0.5)
		SetEntityCoords(ped, x, y, z - 0.5, 1, 0, 0, 1)
		Wait(250)
		hideSpot = nil
	end

	-- event: dumpster:hide
	RegisterNetEvent("dumpster:hide", function()
		if not canHide then return end

		playerPed = PlayerPedId()
		local pcoords = GetEntityCoords(playerPed)

		for i = 1, #dumpsters do
			local model = dumpsters[i]
			local dumpster = model and GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 1.0, model, false, false, false)
			if dumpster then
				local dcoords = GetEntityCoords(dumpster)
				local dist = #(pcoords - dcoords)
				if dist < 2 and not inTrash then
					if not IsEntityAttached(playerPed) or GetDistanceBetweenCoords(pcoords, GetEntityCoords(playerPed), true) >= 5.0 then
						AttachEntityToEntity(playerPed, dumpster, -1, 0.0, -0.3, 2.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
						LoadAnimDict("timetable@floyd@cryingonbed@base")
						TaskPlayAnim(playerPed, "timetable@floyd@cryingonbed@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
						Wait(50)
						SetEntityVisible(playerPed, false, false)
						hideSpot = dumpster
						inTrash = true
						canHide = false
					end
					break
				end
			end
		end
	end)

	CreateThread(function()
		while true do
			if LocalPlayer.state.isLoggedIn and inTrash then
				Wait(5)
				local dumpster = GetEntityAttachedTo(playerPed)
				-- form some reason the dumpster isn't found?
				if not DoesEntityExist(dumpster) then
					Wait(1000)
				else
					playerPed = PlayerPedId()

					-- don't allow entering the dumpster while dead/injured
					if IsPedDeadOrDying(playerPed) or IsPedFatallyInjured(playerPed) then
						ExitDumpster(playerPed)
						Wait(1000)
					else
						Wait(5)

						SetEntityCollision(playerPed, false, false)
						if not IsEntityPlayingAnim(playerPed, "timetable@floyd@cryingonbed@base", 3) then
							LoadAnimDict("timetable@floyd@cryingonbed@base")
							TaskPlayAnim(playerPed, "timetable@floyd@cryingonbed@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
						end

						-- local coords = GetEntityCoords(dumpster)
						while inTrash do
							Wait(5)

							-- TODO: diasble controls
							-- DrawText3D(coords.x, coords.y, coords.z + 1.1, "Press [~f~E~w~] to exit")

							if IsControlJustReleased(0, 38) and inTrash then
								ExitDumpster(playerPed)
							end
						end
					end
				end
			else
				Wait(1000)
			end
		end
	end)

	RegisterCommand("resettrash", function()
		playerPed = PlayerPedId()
		ExitDumpster(playerPed)
	end)

	exports("IsInTrash", function()
		return inTrash
	end)
end

-------------------------------------------------------------------------------
-- common thread

-- one time execution thread
CreateThread(function()
	local targetOptions = nil

	-- storage enabled?
	if Config.storage then
		-- trash bins
		exports["qb-target"]:AddTargetModel(bins, {
			options = {{
				type = "client",
				event = "dumpster:open",
				icon = "fas fa-trash",
				label = "Open",
				target = "bins",
				canInteract = canInteract
			}},
			distance = 1
		})

		-- add open option to dumpsters
		targetOptions = {{
			type = "client",
			event = "dumpster:open",
			icon = "fas fa-dumpster",
			label = "Open",
			target = "dumpsters",
			canInteract = canInteract
		}}
	else
		exports["qb-target"]:RemoveTargetModel(bins)
	end

	-- hiding enabled?
	if Config.canHide then
		targetOptions = targetOptions or {}
		targetOptions[#targetOptions + 1] = {
			type = "client",
			event = "dumpster:hide",
			icon = "fas fa-arrow-circle-down",
			label = "Hide",
			canInteract = canInteract
		}
	end

	-- add to dumpster?
	if targetOptions then
		exports["qb-target"]:AddTargetModel(dumpsters, {
			options = targetOptions,
			distance = 1
		})
	else
		exports["qb-target"]:RemoveTargetModel(dumpsters)
	end
end)
