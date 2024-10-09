--- WORS Slayer Helper Addon
-- Provides location assistance for Slayer tasks

-- print("WORS Slayer Helper Loaded")

-- Create the main addon frame
local slayerTaskFrame = CreateFrame("Frame", "WORSSlayerTaskFrame", UIParent)
slayerTaskFrame:SetSize(300, 140)  -- Adjust size for more text
slayerTaskFrame:SetPoint("TOPRIGHT", -200, -150)  -- Start in the top-right corner, slightly centered
slayerTaskFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
slayerTaskFrame:SetMovable(true)
slayerTaskFrame:EnableMouse(true)
slayerTaskFrame:RegisterForDrag("LeftButton")
slayerTaskFrame:SetScript("OnDragStart", slayerTaskFrame.StartMoving)
slayerTaskFrame:SetScript("OnDragStop", slayerTaskFrame.StopMovingOrSizing)
slayerTaskFrame:Hide()

local titleText = slayerTaskFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -15)
titleText:SetText("WORS Slayer Helper")

-- Create a larger font for the task text without changing its color
local taskText = slayerTaskFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")  -- Keep the original color
taskText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")  -- Set a larger font size
taskText:SetPoint("TOPLEFT", 15, -40)  -- Padding from the left
taskText:SetPoint("TOPRIGHT", -15, -40)  -- Padding from the right
taskText:SetWidth(270)  -- Adjust width for cleaner layout
taskText:SetJustifyH("LEFT")

-- Function to check for active Slayer task
local function CheckSlayerTask()
    for i = 1, GetNumQuestLogEntries() do
        local questLogTitle = GetQuestLogTitle(i)

        if questLogTitle then
            --print("Checking quest: " .. questLogTitle)  -- Debugging

            -- Match slayer task name
            if string.find(questLogTitle, "Slayer Task -") then
                --print("Slayer Task Found: " .. questLogTitle)  -- Debugging

                -- Extract the task name
                local taskName = string.match(questLogTitle, "Slayer Task %- (.+)")
                if taskName then
                    --print("Extracted Task Name: " .. taskName)  -- Debugging

                    -- Check progress
                    local progress, maxProgress = 0, 0
                    local objectiveCount = GetNumQuestLeaderBoards(i)

                    -- Debugging: output the number of objectives
                    --print("Objective Count: " .. objectiveCount)

                    for j = 1, objectiveCount do
                        local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, i)
                        --print("Objective: " .. objectiveText)  -- Debugging
                        --print("Objective Completed: " .. tostring(objectiveCompleted))  -- Debugging
                        --print("Objective Required: " .. tostring(objectiveRequired))  -- Debugging

                        -- Only count 'kill' type objectives
                        if objectiveType == "kill" then
                            if objectiveCompleted then
                                progress = progress + (objectiveRequired or 1)  -- Increment by the required amount if completed
                            end
                            maxProgress = maxProgress + (objectiveRequired or 1)  -- Always add to max progress
                        end
                    end

                    -- Debugging output for progress
                    --print("Progress: " .. progress .. ", Max Progress: " .. maxProgress)

                    return taskName, progress, maxProgress, i  -- Return the quest index too
                else
                    --print("Could not extract task name.")  -- Debugging
                end
            end
        end
    end
    print("No Slayer Task Found")  -- Debugging
    return nil, nil, nil, nil
end

-- Function to display the current task, progress, and locations
local function DisplaySlayerTask()
    --print("DisplaySlayerTask called")  -- Debugging
    local taskName, progress, maxProgress, questIndex = CheckSlayerTask()

    if taskName then
        --print("Displaying Task: " .. taskName)  -- Debugging

        -- Prepare task display text
        local taskProgressText = " "
        -- if progress and maxProgress then
            -- taskProgressText = string.format("Progress: %d/%d", progress, maxProgress)
        -- end

        -- Show the frame and set the task text
        slayerTaskFrame:Show()
        taskText:SetText(taskProgressText)

        -- Fetch and display quest objectives and locations
        if questIndex then
            local objectiveCount = GetNumQuestLeaderBoards(questIndex)
            for j = 1, objectiveCount do
                local objectiveText, objectiveType, objectiveCompleted, objectiveRequired = GetQuestLogLeaderBoard(j, questIndex)
                local currentProgress = objectiveCompleted and objectiveRequired or 0
                taskText:SetText(taskText:GetText() .. objectiveText)
            end

            -- Display location data for the task
            local locations = WORSSlayerTaskData[taskName]
            if locations then
                taskText:SetText(taskText:GetText() .. "\n    " .. table.concat(locations, "\n    "))
            end
        else
            taskText:SetText(taskText:GetText() .. "\nNo objectives found!")
        end
    else
        -- Ensure frame is hidden if no task is found
        slayerTaskFrame:Hide()
        --print("No task to display.")  -- Debugging
    end
end

-- Check task every time the quest log is updated
slayerTaskFrame:RegisterEvent("QUEST_LOG_UPDATE")
slayerTaskFrame:SetScript("OnEvent", function(self, event)
    --print("Quest log updated")  -- Debugging
    DisplaySlayerTask()
end)

print("Event Handler Registered")
