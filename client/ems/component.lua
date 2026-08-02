local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

_evald = {}

local _calledForHelp = false
CreateThread(function()
	plsr.Interaction:RegisterMenu("call-911", "Call For Help", "clipboard-list", function(data)
		plsr.Interaction:Hide()
		TriggerServerEvent("EMS:Server:RequestHelp")
		_calledForHelp = GetCloudTimeAsInt() + (60 * 5)
	end, function()
		return plsr.State.flags.onDuty ~= "ems"
			and plsr.State.flags.onDuty ~= "police"
			and plsr.State.flags.isDead
			and GetCloudTimeAsInt() > plsr.State.flags.isDeadTime + (60 * 2)
			and (not _calledForHelp or GetCloudTimeAsInt() > _calledForHelp)
	end)

	plsr.Interaction:RegisterMenu("ems", false, "clipboard-list", function(data)
		plsr.Interaction:ShowMenu({
			{
				icon = "clipboard-list",
				label = "13-A",
				action = function()
					plsr.Interaction:Hide()
					TriggerServerEvent("EMS:Server:Panic", true)
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
					TriggerServerEvent("EMS:Server:Panic", false)
				end,
				shouldShow = function()
					return plsr.State.flags.isDead
				end,
			},
		})
	end, function()
		return plsr.State.flags.onDuty == "ems" and plsr.State.flags.onDuty and plsr.State.flags.isDead
	end)

	plsr.Interaction:RegisterMenu("ems-utils", "EMS Utilities", "tablet-rugged", function(data)
		plsr.Interaction:ShowMenu({
			{
				icon = "tablet-screen-button",
				label = "MDT",
				action = function()
					plsr.Interaction:Hide()
					TriggerEvent("MDT:Client:Toggle")
				end,
				shouldShow = function()
					return plsr.State.flags.onDuty == "ems"
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
					return plsr.State.flags.onDuty == "ems"
				end,
			},
		})
	end, function()
		return plsr.State.flags.onDuty == "ems"
	end)

	plsr.Callbacks:RegisterClientCallback("EMS:ApplyBandage", function(data, cb)
		SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 10)
		cb(true)
	end)

	plsr.Callbacks:RegisterClientCallback("EMS:Heal", function(data, cb)
		SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + data)
		cb(true)
	end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("EMS", _EMS)
end)

_EMS = {
	HaveEvaluated = function(self, id)
		return _evald[id] ~= nil and _evald[id] > GetGameTimer()
	end,
}

RegisterNetEvent("Characters:Client:Spawn", function()
	local hospitalBlip = config.Hospital.blip
	plsr.Blips:Add("st_fiacre", "Hospital", hospitalBlip.coords, hospitalBlip.sprite, hospitalBlip.colour, hospitalBlip.scale)
end)
