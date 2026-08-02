return {
	Items = { -- inventory item names this resource looks for by RegisterUse and Has() checks
		governmentId = "govid",
		detCord = "det_cord",
		spikes = "spikes",
		medical = {
			tourniquet = "tourniquet",
			morphine = "morphine",
			oxy = "oxy",
			bandage = "bandage",
			gauze = "gauze",
			firstaid = "firstaid",
			ifak = "ifak",
			medicalkit = "medicalkit",
			traumakit = "traumakit",
		},
	},

	GovIdPrice = 500,

	Licenses = { -- key must match the character's Licenses table key; price is also used to build the client menu labels
		drivers = { key = "Drivers", price = 1000, label = "Drivers License" },
		weapons = { key = "Weapons", price = 2000, label = "Weapons License" },
		hunting = { key = "Hunting", price = 800, label = "Hunting License" },
		fishing = { key = "Fishing", price = 800, label = "Fishing License" },
	},
	PoliceWeaponsLicensePrice = 20, -- discounted weapons license price for on-duty police buying their own

	PoliceStationBlips = {
		sprite = 137,
		colour = 38,
		scale = 0.6,
		points = {
			vector3(-445.7, 6013.2, 100.0), -- paleto
			vector3(438.7, -981.8, 100.0), -- mrpd
			vector3(1850.634, 3683.860, 100.0), -- sandy
			vector3(372.658, -1601.816, 100.0), -- davis
		},
	},

	-- jurisdiction polyzones per station, used to flag whether a coord counts as inside a PD station
	PoliceStationZones = {
		{
			points = {
				vector2(419.16091918945, -966.34405517578),
				vector2(419.2200012207, -1016.196105957),
				vector2(409.74496459961, -1016.0508422852),
				vector2(410.03247070312, -1033.0327148438),
				vector2(489.80380249023, -1026.6353759766),
				vector2(488.85284423828, -966.38427734375),
			},
			options = { name = "pdstation_missionrow", minZ = 25.36417388916, maxZ = 45.414678573608 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(411.00393676758, -1661.6872558594),
				vector2(424.06509399414, -1645.6456298828),
				vector2(424.70223999023, -1640.4389648438),
				vector2(423.83392333984, -1627.9958496094),
				vector2(360.71951293945, -1574.7712402344),
				vector2(339.02374267578, -1600.73046875),
			},
			options = { name = "pdstation_davis", minZ = 25.36417388916, maxZ = 45.414678573608 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(818.44097900391, -1249.2879638672),
				vector2(836.80029296875, -1252.8927001953),
				vector2(860.4052734375, -1278.6043701172),
				vector2(862.82849121094, -1296.5511474609),
				vector2(877.03753662109, -1297.9116210938),
				vector2(878.47839355469, -1328.7099609375),
				vector2(878.81671142578, -1361.5606689453),
				vector2(848.46789550781, -1417.4731445312),
				vector2(816.15045166016, -1417.8415527344),
			},
			options = { name = "pdstation_popular", minZ = 25.36417388916, maxZ = 45.414678573608 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(1889.2142333984, 3691.6762695312),
				vector2(1851.7814941406, 3668.3894042969),
				vector2(1830.3732910156, 3704.9562988281),
				vector2(1868.1072998047, 3727.1462402344),
			},
			options = { name = "pdstation_sandy", minZ = 29.36417388916, maxZ = 49.414678573608 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(-442.38430786133, 6062.9243164062),
				vector2(-416.13342285156, 6005.0458984375),
				vector2(-415.57186889648, 5998.3540039062),
				vector2(-439.16738891602, 5975.2041015625),
				vector2(-449.66729736328, 5985.3481445312),
				vector2(-472.04858398438, 5963.1728515625),
				vector2(-500.68542480469, 5991.81640625),
				vector2(-478.4963684082, 6014.41796875),
				vector2(-488.33645629883, 6024.4272460938),
				vector2(-460.89733886719, 6051.8681640625),
			},
			options = { name = "pdstation_paleto", minZ = 29.36417388916, maxZ = 49.414678573608 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(-1102.2563476562, -273.6389465332),
				vector2(-1016.8302001953, -232.33473205566),
				vector2(-1040.9318847656, -211.10615539551),
				vector2(-1101.2906494141, -241.23860168457),
				vector2(-1111.4075927734, -247.7313079834),
			},
			options = { name = "pdstation_guardius", minZ = 25.0, maxZ = 67.4 },
			data = { pdstation = true },
		},
		{
			points = {
				vector2(-127.90340423584, -1157.5145263672),
				vector2(-128.29985046387, -1186.4349365234),
				vector2(-249.06109619141, -1184.8615722656),
				vector2(-247.67953491211, -1157.8649902344),
			},
			options = { name = "pdstation_impound", heading = 0, minZ = 22.04, maxZ = 34.04 },
			data = { pdstation = true },
		},
	},

	-- clock-in/off targeting zones per station
	ClockInPoints = {
		police = {
			{ id = "mrpd", coords = vector3(441.96, -981.94, 30.69), length = 1.2, width = 1.2, options = { heading = 356, minZ = 30.49, maxZ = 31.49 } },
			{ id = "sandy", coords = vector3(1833.55, 3678.69, 34.19), length = 1.0, width = 3.0, options = { heading = 30, minZ = 33.79, maxZ = 35.59 } },
			{ id = "pbpd", coords = vector3(-447.18, 6013.36, 32.29), length = 0.8, width = 1.6, options = { heading = 45, minZ = 32.29, maxZ = 32.89 } },
			{ id = "davis", coords = vector3(381.37, -1595.84, 30.05), length = 2.0, width = 1.0, options = { heading = 320, minZ = 29.85, maxZ = 31.05 } },
			{ id = "lamesa", coords = vector3(837.23, -1289.2, 28.24), length = 0.8, width = 2.2, options = { heading = 0, minZ = 27.24, maxZ = 29.04 } },
			{ id = "courthouse", coords = vector3(-528.46, -189.44, 38.23), length = 1.0, width = 1.0, options = { heading = 30, minZ = 37.63, maxZ = 39.23 } },
			{ id = "guardius", coords = vector3(-1083.75, -247.15, 37.76), length = 1.2, width = 2, options = { heading = 27, minZ = 36.76, maxZ = 38.96 } },
			{ id = "guardius2", coords = vector3(-1049.57, -231.01, 39.02), length = 1, width = 1, options = { heading = 300, minZ = 38.02, maxZ = 40.22 } },
		},
		government = {
			{ coords = vector3(-587.98, -206.59, 38.23), length = 0.8, width = 0.8, options = { heading = 30, minZ = 37.23, maxZ = 38.83 } },
		},
		prison = {
			{ id = "prison-clockinoff-1", coords = vector3(1838.94, 2578.14, 46.01), length = 2.0, width = 0.8, options = { heading = 305, minZ = 45.81, maxZ = 46.61 } },
			{ id = "prison-clockinoff-2", coords = vector3(1773.99, 2493.69, 49.67), length = 0.6, width = 0.4, options = { heading = 30, minZ = 50.02, maxZ = 50.62 } },
			{ id = "prison-clockinoff-3", coords = vector3(1768.84, 2573.73, 45.73), length = 1.4, width = 0.6, options = { heading = 0, minZ = 45.13, maxZ = 46.13 } },
		},
	},

	-- personal-locker targeting zones
	Lockers = {
		police = {
			{ id = "police-shitty-locker", coords = vector3(461.59, -1000.0, 30.69), length = 1.0, width = 3.8, options = { heading = 0, minZ = 29.69, maxZ = 32.69 } },
			{ id = "police-shitty-locker-2", coords = vector3(1841.51, 3682.08, 34.19), length = 2.0, width = 1, options = { heading = 30, minZ = 33.19, maxZ = 35.59 } },
			{ id = "police-shitty-locker-3", coords = vector3(-436.32, 6009.79, 37.0), length = 0.2, width = 2.2, options = { heading = 45, minZ = 36.3, maxZ = 38.1 } },
			{ id = "police-shitty-locker-4", coords = vector3(360.08, -1592.9, 25.45), length = 0.5, width = 2.8, options = { heading = 50, minZ = 24.45, maxZ = 27.45 } },
			{ id = "police-shitty-locker-5", coords = vector3(844.8, -1286.55, 28.24), length = 2.0, width = 1.2, options = { heading = 0, minZ = 27.24, maxZ = 29.84 } },
			{ id = "police-shitty-locker-6", coords = vector3(-1061.09, -247.43, 39.74), length = 3.6, width = 1, options = { heading = 27, minZ = 38.74, maxZ = 41.34 } },
		},
		ems = {
			{ id = "ems-shitty-locker-1", coords = vector3(1142.12, -1539.54, 35.03), length = 4.2, width = 0.6, options = { heading = 0, minZ = 32.23, maxZ = 36.23 } },
		},
		prison = {
			{ id = "prison-shitty-locker", coords = vector3(1833.2, 2574.06, 46.01), length = 5.4, width = 0.4, options = { heading = 0, minZ = 45.01, maxZ = 47.01 } },
		},
	},

	Prison = {
		LockdownZones = {
			{ id = "prison-lockdown-1", coords = vector3(1771.76, 2491.75, 49.67), length = 4.8, width = 0.8, options = { name = "prison-lockdown-target-1", heading = 30, minZ = 49.07, maxZ = 50.07 } },
			{ id = "prison-lockdown-2", coords = vector3(1773.06, 2571.9, 45.73), length = 0.6, width = 0.4, options = { name = "prison-lockdown-target-2", heading = 0, minZ = 45.93, maxZ = 46.93 } },
		},
		CellDoorZone = { coords = vector3(1774.88, 2492.29, 49.67), length = 2.2, width = 0.4, options = { name = "prison-doors-lockup-cells", heading = 30, minZ = 49.77, maxZ = 50.97 } },
	},

	Courthouse = {
		blip = { coords = vector3(-538.916, -214.852, 37.650), sprite = 419, colour = 0, scale = 0.9 },
		zone = { coords = vector3(-571.17, -207.02, 38.77), length = 18.2, width = 19.6, options = { heading = 30, minZ = 36.97, maxZ = 47.37 } },
		gavel = { coords = vector3(-575.8, -210.3, 38.77), length = 0.8, width = 0.8, options = { heading = 30, minZ = 37.77, maxZ = 39.37 } },
	},

	GovtServicesNpc = { coords = vector3(-552.412, -202.760, 37.239), heading = 337.363, dist = 25.0 },

	Hospital = {
		blip = { coords = vector3(1149.516, -1531.912, 35.381), sprite = 61, colour = 42, scale = 0.8 },
	},
}
