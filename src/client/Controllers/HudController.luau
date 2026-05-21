glocal Players = game:GetService("Players")

local OverlayView = require(script.Parent.Parent.Prototype.OverlayView)
local KeybindController = require(script.Parent.Parent.Prototype.KeybindController)
local SlotCatalog = require(script.Parent.Parent.Prototype.SlotCatalog)

local HudController = {}
HudController.__index = HudController

local function formatSeconds(seconds)
	local rounded = math.max(0, math.ceil(seconds or 0))
	local minutes = math.floor(rounded / 60)
	local remainder = rounded % 60

	return string.format("%d:%02d", minutes, remainder)
end

function HudController.new(matchController)
	local self = setmetatable({}, HudController)

	self.matchController = matchController
	self.localPlayer = Players.LocalPlayer
	self.playerGui = self.localPlayer:WaitForChild("PlayerGui")
	self.latestSnapshot = nil
	self.focusLaneId = nil
	self.lastStatusLine = "World blockout online. Rewards and prep auto-advance so you can watch the run."
	self.overlay = OverlayView.new(self.playerGui)

	self.matchController.autoAdvancePrep = true
	self.matchController.autoSelectRewards = true

	self.snapshotDisconnect = self.matchController:onSnapshot(function(snapshot)
		self.latestSnapshot = snapshot
		self:render(snapshot)
	end)

	self.announcementDisconnect = self.matchController:onAnnouncement(function(kind, payload)
		self:_applyAnnouncement(kind, payload)
	end)

	self.keybinds = KeybindController.new({
		onLaneSelected = function(laneId)
			self.focusLaneId = laneId
			self.lastStatusLine = string.format("Focus moved to %s lane.", laneId)
			self:render(self.latestSnapshot)
		end,
		onSkill = function(skillIndex)
			self:_useSkill(skillIndex)
		end,
		onUltimate = function()
			self:_useUltimate()
		end,
		onBuild = function(buildableId)
			self:_placeBuildable(buildableId)
		end,
		onReady = function()
			self.matchController:readyForNextWave()
			self.lastStatusLine = "Manual ready sent."
			self:render(self.latestSnapshot)
		end,
	})

	local latestSnapshot = self.matchController:getLatestSnapshot()

	if latestSnapshot then
		self.latestSnapshot = latestSnapshot
		self:render(latestSnapshot)
	end

	return self
end

function HudController:_getLocalPlayerSnapshot(snapshot)
	return self.matchController:getLocalPlayerSnapshot(snapshot)
end

function HudController:_ensureFocusLane(snapshot)
	local localPlayerSnapshot = self:_getLocalPlayerSnapshot(snapshot)

	if localPlayerSnapshot and (self.focusLaneId == nil or snapshot.lanes[self.focusLaneId] == nil) then
		self.focusLaneId = localPlayerSnapshot.laneId
	end
end

function HudController:_applyAnnouncement(kind, payload)
	if kind == "objective" then
		self.lastStatusLine = string.format("Objective: %s", tostring(payload.text))
	elseif kind == "wave_started" then
		self.lastStatusLine = string.format("Wave %d started: %s", payload.waveIndex or 0, tostring(payload.stage or "Unknown"))
	elseif kind == "modifier_applied" then
		self.lastStatusLine = string.format("Modifier online: %s", tostring(payload.modifierId))
	elseif kind == "map_evolved" then
		self.lastStatusLine = string.format("Map evolved: %s", tostring(payload.mapEvolutionId))
	elseif kind == "run_ended" then
		self.lastStatusLine = string.format("Run ended: %s", tostring(payload.result))
	elseif kind == "system_notice" then
		self.lastStatusLine = tostring(payload.message)
	end

	self:render(self.latestSnapshot)
end

function HudController:_useSkill(skillIndex)
	local snapshot = self.latestSnapshot

	if not snapshot then
		return
	end

	self:_ensureFocusLane(snapshot)

	local localPlayerSnapshot = self:_getLocalPlayerSnapshot(snapshot)

	if not localPlayerSnapshot then
		return
	end

	local skillId = localPlayerSnapshot.loadout.equippedSkillIds[skillIndex]

	if not skillId then
		return
	end

	self.matchController:activateSkill(skillId, self.focusLaneId)
	self.lastStatusLine = string.format("Skill %d fired into %s.", skillIndex, self.focusLaneId)
	self:render(snapshot)
end

function HudController:_useUltimate()
	local snapshot = self.latestSnapshot

	if not snapshot then
		return
	end

	self:_ensureFocusLane(snapshot)

	local localPlayerSnapshot = self:_getLocalPlayerSnapshot(snapshot)

	if not localPlayerSnapshot then
		return
	end

	self.matchController:activateSkill(localPlayerSnapshot.loadout.ultimateId, self.focusLaneId)
	self.lastStatusLine = string.format("Ultimate fired into %s.", self.focusLaneId)
	self:render(snapshot)
end

function HudController:_placeBuildable(buildableId)
	local snapshot = self.latestSnapshot

	if not snapshot then
		return
	end

	self:_ensureFocusLane(snapshot)

	local laneBuilds = snapshot.placedBuildables[self.focusLaneId] or {}
	local slotId = SlotCatalog.getNextOpenSlot(self.focusLaneId, laneBuilds)

	if not slotId then
		self.lastStatusLine = string.format("No free MVP build slots left in %s.", self.focusLaneId)
		self:render(snapshot)
		return
	end

	task.spawn(function()
		local ok, message = self.matchController:placeBuildable({
			buildableId = buildableId,
			laneId = self.focusLaneId,
			slotId = slotId,
			rotationY = 0,
		})

		self.lastStatusLine = ok
			and string.format("%s placed in %s on %s.", buildableId, self.focusLaneId, slotId)
			or string.format("%s rejected: %s", buildableId, tostring(message))

		self:render(self.latestSnapshot)
	end)
end

function HudController:render(snapshot)
	if not snapshot then
		return
	end

	self:_ensureFocusLane(snapshot)

	local localPlayerSnapshot = self:_getLocalPlayerSnapshot(snapshot)
	local localLaneId = localPlayerSnapshot and localPlayerSnapshot.laneId or "None"
	local localScrap = localPlayerSnapshot and localPlayerSnapshot.scrap or 0
	local modifierCount = #snapshot.activeModifierIds

	local laneSummaries = {}

	for _, laneId in ipairs({ "North", "East", "West" }) do
		local laneState = snapshot.lanes[laneId]
		table.insert(laneSummaries, string.format("%s %d HP / %d%%", laneId, laneState.gateHealth, laneState.leakPressure))
	end

	self.overlay:render({
		title = "Praesidium MVP Blockout",
		phase = string.format(
			"%s | Wave %d | Next %d | %s | Modifiers %d",
			snapshot.phase,
			snapshot.waveIndex,
			snapshot.nextWaveIndex,
			formatSeconds(snapshot.secondsRemaining),
			modifierCount
		),
		resources = string.format(
			"Core %d | Local Lane %s | Focus %s | Scrap %d",
			snapshot.coreHealth,
			localLaneId,
			tostring(self.focusLaneId or "None"),
			localScrap
		),
		lanes = string.format(
			"%s\nBuild Route: %s",
			table.concat(laneSummaries, " | "),
			SlotCatalog.describeOrder(self.focusLaneId or "North")
		),
		status = string.format(
			"%s\nAuto flow: prep ready + reward pick are enabled so the run keeps moving.",
			self.lastStatusLine
		),
		controls = "Controls: `1/2/3` lane focus, `Q/E/R` skills, `F` ultimate, `Z/X/C` build Turret/Barricade/UtilityNode, `G` ready",
	})
end

function HudController:destroy()
	if self.snapshotDisconnect then
		self.snapshotDisconnect()
		self.snapshotDisconnect = nil
	end

	if self.announcementDisconnect then
		self.announcementDisconnect()
		self.announcementDisconnect = nil
	end

	if self.keybinds then
		self.keybinds:destroy()
		self.keybinds = nil
	end

	if self.overlay then
		self.overlay:destroy()
		self.overlay = nil
	end
end

return HudController
