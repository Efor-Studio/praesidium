local SlotCatalog = {}

local BUILDABLE_SLOT_SUFFIXES = {
	"Mid-02",
	"Mid-03",
	"Outer-04",
}

function SlotCatalog.getNextOpenSlot(laneId, placedBuildables)
	local occupiedSlots = {}

	for _, buildRecord in ipairs(placedBuildables or {}) do
		occupiedSlots[buildRecord.slotId] = true
	end

	for _, suffix in ipairs(BUILDABLE_SLOT_SUFFIXES) do
		local slotId = string.format("%s-%s", laneId, suffix)

		if not occupiedSlots[slotId] then
			return slotId
		end
	end

	return nil
end

function SlotCatalog.describeOrder(laneId)
	local labels = {}

	for _, suffix in ipairs(BUILDABLE_SLOT_SUFFIXES) do
		table.insert(labels, string.format("%s-%s", laneId, suffix))
	end

	return table.concat(labels, " -> ")
end

return table.freeze(SlotCatalog)
