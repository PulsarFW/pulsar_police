local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

CreateThread(function()
		plsr.Interaction:RegisterMenu("prison", false, "clipboard-list", function(data)
			plsr.Interaction:ShowMenu({
				{
					icon = "clipboard-list",
					label = "13-A",
					action = function()
						plsr.Interaction:Hide()
						TriggerServerEvent("Police:Server:Panic", true)
					end,
					shouldShow = function()
						return plsr.State.flags.isDead
					end,
				},
				{
					icon = "siren",
					label = "13-B",
					action = function()
						plsr.Interaction:Hide()
						TriggerServerEvent("Police:Server:Panic", false)
					end,
					shouldShow = function()
						return plsr.State.flags.isDead
					end,
				},
			})
		end, function()
			return plsr.State.flags.onDuty == "prison" and plsr.State.flags.isDead
		end)

		local lockdownMenu = {
			{
				icon = "lock",
				text = "Enable Lockdown",
				event = "Prison:Client:SetLockdown",
				data = { state = true },
				isEnabled = function()
					return not GlobalState["PrisonLockdown"]
						and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison")
				end,
			},
			{
				icon = "lock-open",
				text = "Disable Lockdown",
				event = "Prison:Client:SetLockdown",
				data = { state = false },
				isEnabled = function()
					return GlobalState["PrisonLockdown"]
						and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison")
				end,
			},
		}

		for k, v in ipairs(config.Prison.LockdownZones) do
			plsr.Targeting.Zones:AddBox(v.id, "door-closed", v.coords, v.length, v.width, v.options, lockdownMenu, 3.0, true)
		end

		local cellDoors = config.Prison.CellDoorZone
		plsr.Targeting.Zones:AddBox("prison-doors-lockup", "door-closed", cellDoors.coords, cellDoors.length, cellDoors.width, cellDoors.options, {
			{
				icon = "lock",
				text = "Lock Cell Doors",
				event = "Prison:Client:SetCellState",
				data = { state = true },
				isEnabled = function()
					return not GlobalState["PrisonCellsLocked"]
						and not GlobalState["PrisonLockdown"]
						and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison")
				end,
			},
			{
				icon = "lock-open",
				text = "Unlock Cell Doors",
				event = "Prison:Client:SetCellState",
				data = { state = false },
				isEnabled = function()
					return GlobalState["PrisonCellsLocked"]
						and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison")
				end,
			},
		}, 3.0, true)

		plsr.Interaction:RegisterMenu("prison-utils", "Corrections Utilities", "tablet-rugged", function(data)
			plsr.Interaction:ShowMenu({
				{
					icon = "lock-keyhole-open",
					label = "Slimjim Vehicle",
					action = function()
						plsr.Interaction:Hide()
						TriggerServerEvent("Police:Server:Slimjim")
					end,
					shouldShow = function()
						local target = plsr.Targeting:GetEntityPlayerIsLookingAt()
						return target
							and target.entity
							and DoesEntityExist(target.entity)
							and IsEntityAVehicle(target.entity)
							and #(GetEntityCoords(target.entity) - GetEntityCoords(PlayerPedId())) <= 2.0
					end,
				},
				{
					icon = "tablet-screen-button",
					label = "MDT",
					action = function()
						plsr.Interaction:Hide()
						TriggerEvent("MDT:Client:Toggle")
					end,
					shouldShow = function()
						return plsr.State.flags.onDuty == "prison"
					end,
				},
				{
					icon = "camera-security",
					label = "Toggle Body Cam",
					action = function()
						plsr.Interaction:Hide()
						TriggerEvent("MDT:Client:ToggleBodyCam")
					end,
					shouldShow = function()
						return plsr.State.flags.onDuty == "prison"
					end,
				},
			})
		end, function()
			return plsr.State.flags.onDuty == "prison"
		end)

		local prisonDutyPoint = {
			{
				icon = "clipboard-list",
				text = "Go On Duty",
				event = "Corrections:Client:OnDuty",
				jobPerms = {
					{
						job = "prison",
						reqOffDuty = true,
					},
				},
			},
			{
				icon = "clipboard-list",
				text = "Go Off Duty",
				event = "Corrections:Client:OffDuty",
				jobPerms = {
					{
						job = "prison",
						reqDuty = true,
					},
				},
			},
			{
				icon = "clipboard-list",
				text = "Go On Duty (Medical)",
				event = "EMS:Client:OnDuty",
				jobPerms = {
					{
						job = "ems",
						workplace = "prison",
						reqOffDuty = true,
					},
				},
			},
			{
				icon = "clipboard-list",
				text = "Go Off Duty (Medical)",
				event = "EMS:Client:OffDuty",
				jobPerms = {
					{
						job = "ems",
						workplace = "prison",
						reqDuty = true,
					},
				},
			},
		}

		for k, v in ipairs(config.ClockInPoints.prison) do
			plsr.Targeting.Zones:AddBox(v.id, "clipboard", v.coords, v.length, v.width, v.options, prisonDutyPoint, 2.0, true)
		end

		local locker = {
			{
				icon = "user-lock",
				text = "Open Personal Locker",
				event = "Police:Client:OpenLocker",
				jobPerms = {
					{
						job = "prison",
						reqDuty = false,
					},
					{
						job = "ems",
						workplace = "prison",
						reqDuty = true,
					},
				},
			},
		}

		for k, v in ipairs(config.Lockers.prison) do
			plsr.Targeting.Zones:AddBox(v.id, "clipboard-list", v.coords, v.length, v.width, v.options, locker, 3.0, true)
		end
end)

_PROGRESS_LOCKDOWN = false

AddEventHandler("Prison:Client:SetLockdown", function(entity, data)
	if not _PROGRESS_LOCKDOWN then
		_PROGRESS_LOCKDOWN = true
		plsr.Callbacks:ServerCallback("Prison:SetLockdown", data.state, function(success, state)
			if success then
				if state then
					plsr.Notification:Success("Lockdown Initiated")
					TriggerServerEvent("Prison:Server:Lockdown:AlertPolice", state)
				else
					plsr.Notification:Success("Lockdown Disabled")
					TriggerServerEvent("Prison:Server:Lockdown:AlertPolice", state)
				end

				Citizen.SetTimeout(5000, function()
					_PROGRESS_LOCKDOWN = false
				end)
			else
				plsr.Notification:Success("Unauthorized!")
			end
		end)
	end
end)

_PROGRESS_DOORS = false

AddEventHandler("Prison:Client:SetCellState", function(entity, data)
	if not _PROGRESS_DOORS then
		_PROGRESS_DOORS = true
		plsr.Callbacks:ServerCallback("Prison:SetCellState", data.state, function(success, state)
			if success then
				if state then
					plsr.Notification:Success("Cell Doors Locked")
				else
					plsr.Notification:Success("Cell Doors Unlocked")
				end

				-- TriggerEvent("Prison:Client:JailAlarm", data.state)
				Citizen.SetTimeout(5000, function()
					_PROGRESS_DOORS = false
				end)
			else
				plsr.Notification:Success("Unauthorized!")
			end
		end)
	end
end)

RegisterNetEvent("Prison:Client:JailAlarm")
AddEventHandler("Prison:Client:JailAlarm", function(toggle)
	if toggle then
		local alarmIpl = GetInteriorAtCoordsWithType(1787.004, 2593.1984, 45.7978, "int_prison_main")

		RefreshInterior(alarmIpl)
		EnableInteriorProp(alarmIpl, "prison_alarm")

		CreateThread(function()
			while not PrepareAlarm("PRISON_ALARMS") do
				Wait(100)
			end
			StartAlarm("PRISON_ALARMS", true)
		end)
	else
		local alarmIpl = GetInteriorAtCoordsWithType(1787.004, 2593.1984, 45.7978, "int_prison_main")

		RefreshInterior(alarmIpl)
		DisableInteriorProp(alarmIpl, "prison_alarm")

		CreateThread(function()
			while not PrepareAlarm("PRISON_ALARMS") do
				Wait(100)
			end
			StopAllAlarms(true)
		end)
	end
end)
