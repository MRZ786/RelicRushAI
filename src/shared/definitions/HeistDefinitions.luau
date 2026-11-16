--!strict
-- HeistDefinitions.luau
-- Authoritative configuration for heists in Relic Rush

export type HeistExtractionPoint = {
	pointId: string,
	name: string,
	description: string,
	relativePosition: Vector3,
}

export type HeistDefinition = {
	heistId: string,
	name: string,
	difficulty: string,
	targetRelicId: string,
	completionCashReward: number,
	completionShardsReward: number,
	timeLimitSeconds: number,
	alarmThresholds: {
		guarded: number,
		alert: number,
		lockdown: number,
	},
	tripwireAlarmPenalty: number,
	extractionPoints: { HeistExtractionPoint },
}

local HeistDefinitions: { [string]: HeistDefinition } = {
	["heist_obsidian_outpost"] = {
		heistId = "heist_obsidian_outpost",
		name = "The Obsidian Outpost",
		difficulty = "Apprentice",
		targetRelicId = "relic_obsidian_chalice",
		completionCashReward = 300,
		completionShardsReward = 15,
		timeLimitSeconds = 150,
		alarmThresholds = {
			guarded = 35,
			alert = 70,
			lockdown = 100,
		},
		tripwireAlarmPenalty = 25,
		extractionPoints = {
			{
				pointId = "exit_alpha",
				name = "Main Vault Gate",
				description = "Direct courtyard route. Fast escape, but highly exposed.",
				relativePosition = Vector3.new(0, 2, -70),
			},
			{
				pointId = "exit_beta",
				name = "Shadow Drain Flume",
				description = "Concealed waterway exit. Low alarm footprint.",
				relativePosition = Vector3.new(65, 2, 20),
			},
			{
				pointId = "exit_gamma",
				name = "Deep Catacombs Grate",
				description = "Concealed subterranean sewer escape. Furthest distance, lowest alarm footprint.",
				relativePosition = Vector3.new(-65, 2, 20),
			},
		},
	},
}

return {
	All = HeistDefinitions,

	Get = function(heistId: string): HeistDefinition?
		return HeistDefinitions[heistId]
	end,
}
