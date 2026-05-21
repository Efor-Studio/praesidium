local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local RemoteNames = require(Shared.Networking.RemoteNames)

local MatchController = {}
MatchController.__index = MatchController

function MatchController.new(remotes)
	local self = setmetatable({}, MatchController)

	self.localPlayer = Players.LocalPlayer
	self.remotes = remotes
	self.latestSnapshot = nil
	self.hasSubmittedDefaultLoadout = false
	self.lastReadyWaveIndex = -1
	self.lastRewardChoiceKey = nil
	self.lastStatusKey = nil
	self.autoAdvancePrep = false
	self.autoSelectRewards = false
	self.snapshotListeners = {}
	self.announcementListeners = {}

	self:_connect()

	return self
end

function MatchController:_connect()
	self.remotes[RemoteNames.MatchSnapshot].OnClientEvent:Connect(function(snapshot)
		self:_handleSnapshot(snapshot)
	end)

	self.remotes[RemoteNames.MatchAnnouncement].OnClientEvent:Connect(function(kind, payload)
		self:_handleAnnouncement(kind, payload)
	end)
end

function MatchController:bootstrap()
	if self.hasSubmittedDefaultLoadout then
		return
	end

	local ok, message = self:selectLoadout(GameConfig.DefaultLoadout)

	if ok then
		self.hasSubmittedDefaultLoadout = true
	else
		warn(string.format("[Praesidium] Failed to submit bootstrap loadout: %s", tostring(message)))
	end
end

function MatchController:selectLoadout(loadout)
	return self.remotes[RemoteNames.SelectLoadout]:InvokeServer(loadout)
end

function MatchController:activateSkill(skillId, laneId)
	self.remotes[RemoteNames.ActivateSkill]:FireServer({
		skillId = skillId,
		laneId = laneId,
	})
end

function MatchController:placeBuildable(request)
	return self.remotes[RemoteNames.PlaceBuildable]:InvokeServer(request)
end

function MatchController:chooseRewardCard(rewardCardId)
	return self.remotes[RemoteNames.ChooseRewardCard]:InvokeServer(rewardCardId)
end

function MatchController:readyForNextWave()
	self.remotes[RemoteNames.ReadyForNextWave]:FireServer()
end

function MatchController:getLatestSnapshot()
	return self.latestSnapshot
end

function MatchController:getLocalPlayerSnapshot(snapshot)
	local latestSnapshot = snapshot or self.latestSnapshot

	if not latestSnapshot then
		return nil
	end

	return self:_getLocalPlayerSnapshot(latestSnapshot)
end

function MatchController:onSnapshot(listener)
	table.insert(self.snapshotListeners, listener)

	return function()
		local index = table.find(self.snapshotListeners, listener)

		if index then
			table.remove(self.snapshotListeners, index)
		end
	end
end

function MatchController:onAnnouncement(listener)
	table.insert(self.announcementListeners, listener)

	return function()
		local index = table.find(self.announcementListeners, listener)

		if index then
			table.remove(self.announcementListeners, index)
		end
	end
end

function MatchController:_getLocalPlayerSnapshot(snapshot)
	for _, playerSnapshot in ipairs(snapshot.players) do
		if playerSnapshot.userId == self.localPlayer.UserId then
			return playerSnapshot
		end
	end

	return nil
end

function MatchController:_handleSnapshot(snapshot)
	self.latestSnapshot = snapshot

	if not self.hasSubmittedDefaultLoadout then
		self:bootstrap()
	end

	local statusKey = string.format("%s:%d:%d", snapshot.phase, snapshot.waveIndex, math.ceil(snapshot.secondsRemaining))

	if self.lastStatusKey ~= statusKey then
		self.lastStatusKey = statusKey
		print(string.format(
			"[Praesidium] %s | wave %d | next %d | %.1fs",
			snapshot.phase,
			snapshot.waveIndex,
			snapshot.nextWaveIndex,
			snapshot.secondsRemaining
		))
	end

	local localPlayerState = self:_getLocalPlayerSnapshot(snapshot)

	if not localPlayerState then
		for _, listener in ipairs(self.snapshotListeners) do
			local ok, errorMessage = pcall(listener, snapshot)

			if not ok then
				warn(string.format("[Praesidium] Snapshot listener failed: %s", tostring(errorMessage)))
			end
		end

		return
	end

	if self.autoAdvancePrep and snapshot.phase == "Prep" and not localPlayerState.readyForNextWave and self.lastReadyWaveIndex ~= snapshot.waveIndex then
		self.lastReadyWaveIndex = snapshot.waveIndex
		self:readyForNextWave()
	end

	if self.autoSelectRewards and (snapshot.phase == "Reward" or snapshot.phase == "BossReward") and snapshot.pendingReward then
		local options = snapshot.pendingReward.optionsByUserId[tostring(self.localPlayer.UserId)]

		if options and #options > 0 then
			local choiceKey = string.format("%d:%s", snapshot.pendingReward.waveIndex, options[1])

			if self.lastRewardChoiceKey ~= choiceKey then
				self.lastRewardChoiceKey = choiceKey
				local ok, message = self:chooseRewardCard(options[1])

				if not ok then
					warn(string.format("[Praesidium] Reward choice failed: %s", tostring(message)))
				end
			end
		end
	end

	for _, listener in ipairs(self.snapshotListeners) do
		local ok, errorMessage = pcall(listener, snapshot)

		if not ok then
			warn(string.format("[Praesidium] Snapshot listener failed: %s", tostring(errorMessage)))
		end
	end
end

function MatchController:_handleAnnouncement(kind, payload)
	if kind == "objective" then
		print(string.format("[Praesidium] Objective: %s", payload.text))
	elseif kind == "wave_started" then
		print(string.format("[Praesidium] Wave %d started: %s", payload.waveIndex, payload.stage))
	elseif kind == "modifier_applied" then
		print(string.format("[Praesidium] Modifier applied: %s", tostring(payload.modifierId)))
	elseif kind == "map_evolved" then
		print(string.format("[Praesidium] Map evolution triggered: %s", tostring(payload.mapEvolutionId)))
	elseif kind == "run_ended" then
		print(string.format("[Praesidium] Run ended: %s", tostring(payload.result)))
	elseif kind == "system_notice" then
		warn(string.format("[Praesidium] %s", tostring(payload.message)))
	end

	for _, listener in ipairs(self.announcementListeners) do
		local ok, errorMessage = pcall(listener, kind, payload)

		if not ok then
			warn(string.format("[Praesidium] Announcement listener failed: %s", tostring(errorMessage)))
		end
	end
end

return MatchController
