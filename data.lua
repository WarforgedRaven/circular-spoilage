------------------------------------------ SETTINGS -----------------------------------------
local settingLoopNumber = settings.startup["circular-spoilage-loop-number"].value
local settingEvenLoop = settings.startup["circular-spoilage-even-loops"].value
local settingLoopRange = settings.startup["circular-spoilage-irregularity-number"].value
local settingUseCustomTime = settings.startup["circular-spoilage-custom-spoil-time"].value
local settingSpoilMin = settings.startup["circular-spoilage-custom-spoil-min"].value
local settingSpoilMax = settings.startup["circular-spoilage-custom-spoil-max"].value
---------------------------------------------------------------------------------------------

local itemTable = table.deepcopy(data.raw["item"])
local totalItems = 0
local keyHolder = {}
local randomholder = {}
-- 60 ticks * 60 seconds for 5 and 60 minutes
local spoilMin = 60 * 60 * 5
local spoilMax = 60 * 60 * 60

if settingUseCustomTime then
    spoilMin = settingSpoilMin * 60
    spoilMax = settingSpoilMax * 60
end

-- Determine how many items each spoilage loop will contain
-- Find how many items are in the game
for key, value in pairs(itemTable) do
    if value.hidden == nil and value.parameter == nil and value.subgroup ~= "spawnables" then
        totalItems = totalItems + 1
        keyHolder[totalItems] = key
        randomholder[key] = math.random(0, 1000)
    end
end

table.sort(keyHolder,
    function(a, b)
        return randomholder[a] > randomholder[b]
    end
)

-- Divide that by the number of desired spoilage loop
local itemsPerLoop = {}

for i = 1, settingLoopNumber, 1 do
    local amountPerLoop = math.floor(totalItems / settingLoopNumber)
    -- Fudge the numbers a bit if the setting is for imperfect loops, by the amount in settings
    if not settingEvenLoop then
        local range = math.floor(settingLoopRange * amountPerLoop / 100)
        amountPerLoop = amountPerLoop + math.random(-range, range)
    end

    -- The last spoilage loop is set to the max number to make sure no item is not in a spoilage loop
    if i == settingLoopNumber then
        amountPerLoop = totalItems
    end

    itemsPerLoop[i] = amountPerLoop
end

-- Keeps count of the current spoilage loop
local currentLoop = 1
-- Keeps count of items per spoilage loop
local iterationCounter = 1
-- Keeps track of the first item of the spoilage loop
local firstItem = nil
-- Keeps track of the previous spoilage loop's item
local previousItem = nil

for i = 1, totalItems, 1 do
    local key = keyHolder[i]
    local currentItem = itemTable[key]

    -- Draw an unused item
    -- On the first loop
    if iterationCounter == 1 then
        -- Keep track of the first item to set it to spoil to the last item in the spoilage loop
        firstItem = key
    end

    -- if the temporary variable is not nil then it is not the first item in the loop
    if previousItem ~= nil then
        -- set the current item to spoil to the previous item
        currentItem.spoil_result = previousItem
        currentItem.spoil_ticks = math.random(spoilMin, spoilMax)
        currentItem.spoil_to_trigger_result = nil

        data.extend({ currentItem })
    end

    -- On the last loop
    if iterationCounter == itemsPerLoop[currentLoop] then
        -- Set the first item to spoil to the last item
        local firstItem = itemTable[firstItem]
        firstItem.spoil_result = key
        firstItem.spoil_ticks = math.random(spoilMin, spoilMax)
        firstItem.spoil_to_trigger_result = nil

        data.extend({ firstItem })
    end

    -- Keep the current item in memory to be used in the next loop
    previousItem = key

    -- increment the item counter
    iterationCounter = iterationCounter + 1

    if iterationCounter > itemsPerLoop[currentLoop] then
        ---------------------------------------------
        -- Logic to proceed to the next spoilage loop
        ---------------------------------------------
        -- increment the current spoilage loop counter by one
        currentLoop = currentLoop + 1
        -- reset the other trackers
        iterationCounter = 1
        firstItem = nil
        previousItem = nil
        ---------------------------------------------
    end
end
