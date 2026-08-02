local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

local _pdModels = {}
local _emsModels = {}

local lastTackle = 0

local _breached = {}

local policeDutyPoint = {
	{
		icon = "clipboard-list",
		text = "Go On Duty",
		event = "Police:Client:OnDuty",
		jobPerms = {
			{
				job = "police",
				reqOffDuty = true,
			},
		},
	},
	{
		icon = "clipboard",
		text = "Go Off Duty",
		event = "Police:Client:OffDuty",
		jobPerms = {
			{
				job = "police",
				reqDuty = true,
			},
		},
	},
	{
		icon = "location-dot",
		text = "Re-Enable Tracker",
		event = "Police:Client:ReEnableTracker",
		isEnabled = function()
			return plsr.State.flags.trackerDisabled
		end,
	},
}

function loadModel(model)
	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(1)
	end
end

CreateThread(function()
		plsr.State.flags.inPdStation = false

		_pdModels = GlobalState["PoliceCars"]
		_emsModels = GlobalState["EMSCars"]

		plsr.Interaction:RegisterMenu("police", false, "clipboard-list", function(data)
			plsr.Interaction:ShowMenu({
				{
					icon = "land-mine-on",
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
					icon = "clipboard-list",
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
			return plsr.State.flags.onDuty == "police" and plsr.State.flags.isDead
		end)

		plsr.Interaction:RegisterMenu("police-raid-biz", "Search Inventory", "magnifying-glass", function(data)
			plsr.Interaction:Hide()
			plsr.Progress:ProgressWithTickEvent({
				name = 'pd_raid_biz',
				duration = 8000,
				label = "Searching",
				tickrate = 250,
				useWhileDead = false,
				canCancel = true,
				vehicle = false,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableCombat = true,
				},
				animation = {
					animDict = "anim@gangops@facility@servers@bodysearch@",
					anim = "player_search",
					flags = 49,
				},
			}, function()
				if plsr.State.flags.onDuty == "police" and not plsr.State.flags.isDead and plsr.State.flags._inInvPoly ~= nil then
					return
				end
				plsr.Progress:Cancel()
			end, function(cancelled)
				_doing = false
				if not cancelled then
					plsr.Callbacks:ServerCallback("Inventory:Raid", plsr.State.flags._inInvPoly.inventory, function(owner) end)
				end
			end)
		end, function()
			return plsr.State.flags.onDuty == "police"
					and not plsr.State.flags.isDead
					and plsr.State.flags._inInvPoly ~= nil
					and plsr.State.flags._inInvPoly?.business ~= nil
		end)

		plsr.Interaction:RegisterMenu("pd-locked-veh", "Secured Compartment", "shield-keyhole", function(data)
			plsr.Interaction:Hide()
			plsr.Progress:Progress({
				name = "pd_rack_prog",
				duration = 2000,
				label = "Unlocking Compartment",
				useWhileDead = false,
				canCancel = true,
				animation = false,
			}, function(status)
				if not status then
					plsr.Callbacks:ServerCallback("Police:AccessRifleRack")
				end
			end)
		end, function()
			local v = GetVehiclePedIsIn(PlayerPedId())
			return (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison") and not plsr.State.flags.isDead and v ~= 0 and _pdModels[GetEntityModel(v)] and plsr.Vehicles:HasAccess(v)
		end)

		plsr.Interaction:RegisterMenu("police-utils", "Police Utilities", "tablet", function(data)
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
						return plsr.State.flags.onDuty == "police"
					end,
				},
				{
					icon = "video",
					label = "Toggle Body Cam",
					action = function()
						plsr.Interaction:Hide()
						TriggerEvent("MDT:Client:ToggleBodyCam")
					end,
					shouldShow = function()
						return plsr.State.flags.onDuty == "police"
					end,
				},
				{
					icon = "car-burst",
					label = "Start Pit Timer (5 Mins)",
					action = function()
						plsr.Interaction:Hide()
                        plsr.Notification:Custom("5 Minute Pit Timer", 60 * 1000 * 5, 'car-burst', {
                            alert = {
                                background = "#247BA5B3",
                            },
                            progress = {
                                background = "#ffffff",
                            },
                        })

                        Citizen.SetTimeout(60 * 1000 * 5, function()
                            plsr.UISounds.Play:FrontEnd(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET")
                        end)
					end,
					shouldShow = function()
						return plsr.State.flags.onDuty == "police"
					end,
				},
			})
		end, function()
			return plsr.State.flags.onDuty == "police"
		end)

		plsr.Interaction:RegisterMenu("pd-breach", "Breach", "bomb", function(data)
			local prop = plsr.Properties:Get(data.propertyId)
			plsr.Interaction:ShowMenu({
				{
					icon = "house",
					label = "Breach Property",
					action = function()
						plsr.Interaction:Hide()
						plsr.Callbacks:ServerCallback("Police:Breach", {
							type = "property",
							property = data.propertyId,
						}, function(s)
							if s then

							end
						end)
					end,
					shouldShow = function()
						return prop ~= nil and prop.sold
					end,
				},
				{
					icon = "window-frame-open",
					label = "Breach Apartment",
					action = function()
						plsr.Interaction:Hide()
						plsr.Input:Show("Breaching", "Unit Number (Owner State ID)", {
							{
								id = "unit",
								type = "number",
								options = {},
							},
						}, "Police:Client:DoApartmentBreach", data.id)
					end,
					shouldShow = function()
						return plsr.Apartment:GetNearApartment()
					end,
				},
			})
		end, function()
			if plsr.State.flags.onDuty and plsr.State.flags.onDuty == "police" then
				return plsr.Properties:GetNearHouse() or plsr.Apartment:GetNearApartment()
			else
				return nil
			end
		end)

		plsr.Interaction:RegisterMenu("pd-breach-robbery", "Breach House Robbery", "bomb", function(data)
			local bruh = GlobalState["Robbery:InProgress"]
			for k, v in ipairs(bruh) do
				local fuck = GlobalState[string.format("Robbery:Inplsr.Progress:%s", v)]
				if fuck then
					local dist = #(vector3(plsr.State.flags.position.x, plsr.State.flags.position.y, plsr.State.flags.position.z) - vector3(fuck.x, fuck.y, fuck.z))
					if dist <= 3.0 then
						plsr.Callbacks:ServerCallback("Police:Breach", {
							type = "robbery",
							property = v,
						})

						return
					end
				end
			end
			plsr.Interaction:Hide()
		end, function()
			if plsr.State.flags.onDuty and plsr.State.flags.onDuty == "police" then
				local bruh = GlobalState["Robbery:InProgress"]
				for k, v in ipairs(bruh) do
					local fuck = GlobalState[string.format("Robbery:Inplsr.Progress:%s", v)]
					if fuck then
						local dist = #(vector3(plsr.State.flags.position.x, plsr.State.flags.position.y, plsr.State.flags.position.z) - vector3(fuck.x, fuck.y, fuck.z))
						if dist <= 3.0 then
							return true
						end
					end
				end
			end
			return false
		end)

		plsr.Callbacks:RegisterClientCallback("Police:PanicButton", function(data, cb)
			plsr.Progress:Progress({
				name = "panic_button",
				duration = 2000,
				label = "Activating Panic Button",
				useWhileDead = true,
				canCancel = true,
				disarm = false,
				controlDisables = {
					disableMovement = false,
					disableCarMovement = false,
					disableMouse = false,
					disableCombat = true,
				},
				animation = {
					-- animDict = "missfbi3_sniping",
					-- anim = "male_unarmed_b",
					animDict = "missfbi3_steve_phone",
					anim = "steve_phone_reaction",
					flags = 48,
				},
			}, function(cancelled)
				cb(cancelled)
			end)
		end)

		plsr.Callbacks:RegisterClientCallback("Police:Breach", function(data, cb)
			plsr.Progress:Progress({
				name = "breach_action",
				duration = 3000,
				label = "Breaching",
				useWhileDead = false,
				canCancel = true,
				disarm = false,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
				animation = {
					animDict = "missprologuemcs_1",
					anim = "kick_down_player_zero",
					flags = 49,
				},
			}, function(cancelled)
				cb(not cancelled)
				if not cancelled then
					--Sounds.Play:Location(plsr.State.flags.position, 20, "breach.ogg", 0.15)
				end
			end)
		end)

		local switchModels = {
			[`mp_m_freemode_01`] = true,
			[`mp_f_freemode_01`] = true,
		}
		plsr.Callbacks:RegisterClientCallback("Police:DoDetCord", function(data, cb)
			local cDoorId, cDoorEnt, cDoorCoords = plsr.Doors:GetCurrentDoor()
			if cDoorId and plsr.Doors:IsLocked(cDoorId) then
				CreateThread(function()
					local playerPed = PlayerPedId()
					local playerPos = GetEntityCoords(playerPed, false)
					local doorPosition = playerPos + GetEntityForwardVector(playerPed)
					if #(playerPos - doorPosition) < 1.0 then print("To far away") return cb(false); end
					local raycast = StartShapeTestSweptSphere(playerPos.x, playerPos.y, playerPos.z, doorPosition.x, doorPosition.y, doorPosition.z, 0.2, 16, playerPed, 4)
					local retval, hit, endCoords, surfaceNormal, entity = GetShapeTestResult(raycast)

					-- Apparently This Can Happen Sometimes so better just setting to door coords instead of halfway across map
					if endCoords == vector3(0, 0, 0) then
						endCoords = cDoorCoords
					end

					RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
					RequestModel("hei_p_m_bag_var22_arm_s")
					while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") and not HasModelLoaded("hei_p_m_bag_var22_arm_s") do
					  Wait(0)
					end
					local ped = PlayerPedId()
					Wait(100)
					local rotx, roty, rotz = table.unpack(vec3(GetEntityRotation(ped)))
					local bagscene = NetworkCreateSynchronisedScene(endCoords.x, endCoords.y, endCoords.z, rotx, roty, rotz, 2, false, false, 1065353216, 0, 1.3)
					NetworkAddPedToSynchronisedScene(ped, bagscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
					local curVar = 0
					if switchModels[GetEntityModel(PlayerPedId())] then
					  GetPedDrawableVariation(ped, 5)
					  SetPedComponentVariation(ped, 5, 0, 0, 0)
					end
					NetworkStartSynchronisedScene(bagscene)
					Wait(1500)
					local x, y, z = table.unpack(GetEntityCoords(ped))
					local bomba = CreateObject(GetHashKey("hei_prop_heist_thermite"), x, y, z + 0.2,  true,  true, true)
					SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(bomba), false)
					SetEntityCollision(bomba, false, true)
					AttachEntityToEntity(bomba, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
					Wait(4000)
					if curVar > 0 then
					  SetPedComponentVariation(ped, 5, curVar, 0, 0)
					end
					DetachEntity(bomba, 1, 1)
					FreezeEntityPosition(bomba, true)
					NetworkStopSynchronisedScene(bagscene)
					TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, 0, 0, 0)
					TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 6000, 49, 1, 0, 0, 0)
					plsr.Callbacks:ServerCallback("Robbery:DoThermiteFx", {
						delay = 7000,
						netId = ObjToNet(bomba)
					}, function() end)
					Wait(7000)
					
					plsr.Callbacks:ServerCallback("Robbery:DoDetCordFx", {
						x = endCoords.x,
						y = endCoords.y,
						z = endCoords.z,
						h = GetEntityHeading(cDoorEnt),
					}, function() end)
	
					ClearPedTasks(ped) 
					DeleteObject(bomba)
					cb(true, cDoorId)
				end)  
			end
		end)

		local _cuffCd = false
		plsr.Keybinds:Add("pd_cuff", "LBRACKET", "keyboard", "Police - Cuff", function()
			if plsr.State.flags.loggedIn and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison") then
				if not _cuffCd then
					TriggerServerEvent("Police:Server:Cuff")
					_cuffCd = true
					Citizen.SetTimeout(3000, function()
						_cuffCd = false
					end)
				end
			end
		end)

		plsr.Keybinds:Add("pd_uncuff", "RBRACKET", "keyboard", "Police - Uncuff", function()
			if plsr.State.flags.loggedIn and (plsr.State.flags.onDuty == "police" or plsr.State.flags.onDuty == "prison") then
				if not _cuffCd then
					TriggerServerEvent("Police:Server:Uncuff")
					_cuffCd = true
					Citizen.SetTimeout(3000, function()
						_cuffCd = false
					end)
				end
			end
		end)

		-- Keybinds:Add("pd_toggle_cuff", "", "keyboard", "Police - Cuff / Uncuff", function()
		-- 	if plsr.State.flags.loggedIn and plsr.State.flags.onDuty == "police" then
		-- 		if not _cuffCd then
		-- 			TriggerServerEvent("Police:Server:ToggleCuff")
		-- 			_cuffCd = true
		-- 			CreateThread(function()
		-- 				Wait(2000)
		-- 				_cuffCd = false
		-- 			end)
		-- 		end
		-- 	end
		-- end)

		plsr.Keybinds:Add("tackle", "", "keyboard", "Tackle", function()
			if plsr.State.flags.loggedIn then
				if
					not plsr.State.flags.isCuffed
					and not plsr.State.flags.tpLocation
					and not IsPedInAnyVehicle(PlayerPedId())
					and not plsr.State.flags.playingCasino
				then
					if GetEntitySpeed(PlayerPedId()) > 2.0 then
						local cPlayer, dist = plsr.Game.Players:GetClosestPlayer()
						local tarPlayer = GetPlayerServerId(cPlayer)
						if tarPlayer ~= 0 and dist <= 2.0 and GetGameTimer() - lastTackle > 7000 then
							lastTackle = GetGameTimer()
							TriggerServerEvent("Police:Server:Tackle", tarPlayer)

							loadAnimDict("swimming@first_person@diving")

							if
								IsEntityPlayingAnim(
									PlayerPedId(),
									"swimming@first_person@diving",
									"dive_run_fwd_-45_loop",
									3
								)
							then
								ClearPedSecondaryTask(PlayerPedId())
							else
								-- TaskPlayAnim(
								-- 	PlayerPedId(),
								-- 	"swimming@first_person@diving",
								-- 	"dive_run_fwd_-45_loop",
								-- 	8.0,
								-- 	-8,
								-- 	-1,
								-- 	49,
								-- 	0,
								-- 	0,
								-- 	0,
								-- 	0
								-- )
								-- Wait(350)
								StupidRagdoll(true)
								-- ClearPedSecondaryTask(PlayerPedId())
								-- SetPedToRagdoll(PlayerPedId(), 500, 500, 0, 0, 0, 0)
							end
						else
							--StupidRagdoll(true)
						end
					else
						--StupidRagdoll(false)
					end
				end
			end
		end)

		for k, v in ipairs(config.ClockInPoints.police) do
			plsr.Targeting.Zones:AddBox("pd-clockinoff-" .. v.id, "clipboard-list", v.coords, v.length, v.width, v.options, policeDutyPoint, 2.0, true)
		end

		for k, v in ipairs(config.PoliceStationZones) do
			plsr.Polyzone.Create:Poly(v.options.name, v.points, v.options, v.data)
		end

		plsr.Callbacks:RegisterClientCallback("Police:DeploySpikes", function(data, cb)
			plsr.Progress:ProgressWithStartEvent({
				name = "spikestrips",
				duration = 1000,
				label = "Laying Spikes",
				useWhileDead = false,
				canCancel = true,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
				animation = {
					animDict = "weapons@first_person@aim_rng@generic@projectile@thermal_charge@",
					anim = "plant_floor",
				},
				disarm = true,
			}, function()
				plsr.Weapons:UnequipIfEquippedNoAnim()
			end, function(status)
				if not status then
					local h = GetEntityHeading(PlayerPedId())
					local positions = {}
					for i = 1, 3 do
						table.insert(
							positions,
							GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, -1.5 + (3.5 * i), 0.15)
						)
					end
					cb({
						positions = positions,
						h = h,
					})
				else
					cb(nil)
				end
			end)
		end)

		local locker = {
			{
				icon = "user-lock",
				text = "Open Personal Locker",
				event = "Police:Client:OpenLocker",
				jobPerms = {
					{
						job = "police",
						reqDuty = false,
					},
				},
			},
		}

		for k, v in ipairs(config.Lockers.police) do
			plsr.Targeting.Zones:AddBox(v.id, "clipboard-list", v.coords, v.length, v.width, v.options, locker, 3.0, true)
		end

		local emsLocker = {
			{
				icon = "user-lock",
				text = "Open Personal Locker",
				event = "Police:Client:OpenLocker",
				jobPerms = {
					{
						job = "ems",
						reqDuty = false,
					},
				},
			},
		}

		for k, v in ipairs(config.Lockers.ems) do
			plsr.Targeting.Zones:AddBox(v.id, "clipboard-list", v.coords, v.length, v.width, v.options, emsLocker, 3.0, true)
		end
end)

AddEventHandler("Police:Client:DoApartmentBreach", function(values, data)
	plsr.Callbacks:ServerCallback("Police:Breach", {
		type = "apartment",
		property = tonumber(values.unit),
		id = data,
	}, function(s)
		if s then
			
		end
	end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Police", POLICE)
end)

RegisterNetEvent("Characters:Client:Spawn", function()
	local stationBlips = config.PoliceStationBlips
	for k, v in ipairs(stationBlips.points) do
		plsr.Blips:Add("police_station_" .. k, "Police Department", v, stationBlips.sprite, stationBlips.colour, stationBlips.scale)
	end
end)

RegisterNetEvent("Police:Client:Breached", function(type, id)
	_breached[type] = _breached[type] or {}
	_breached[type][id] = GetCloudTimeAsInt() + (60 * 5)
end)

RegisterNetEvent("Police:Client:GetTackled", function(s)
	if plsr.State.flags.loggedIn then
		SetPedToRagdoll(PlayerPedId(), math.random(3000, 5000), math.random(3000, 5000), 0, 0, 0, 0)
		lastTackle = GetGameTimer()
	end
end)

POLICE = {
	IsPdCar = function(self, entity)
		return _pdModels[GetEntityModel(entity)]
	end,
	IsEMSCar = function(self, entity)
		return _emsModels[GetEntityModel(entity)]
	end
}

function StupidRagdoll(tackleAnim)
	local time = 3500
	if tackleAnim then
		TaskPlayAnim(
			PlayerPedId(),
			"swimming@first_person@diving",
			"dive_run_fwd_-45_loop",
			8.0,
			-8,
			-1,
			49,
			0,
			0,
			0,
			0
		)
		-- time = 1000
	end
	Wait(350)
	ClearPedSecondaryTask(PlayerPedId())
	SetPedToRagdoll(PlayerPedId(), time, time, 0, 0, 0, 0)
end
