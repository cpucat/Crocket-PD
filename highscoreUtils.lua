local defaultScoreTable = {1, 5, 10, 13, 15, 17, 19, 20, 22, 30}
local defaultNameTable = {"Player", "Trash", "AAAAAAAA", "DarnIDie", "Average", "HIMOM", "CoolGuy", "Good", "Cpucat", "GamerMan"}
local runtimeScoreTable
local runtimeNameTable

local runtimeReduceFlashing = false

-- Function that saves game data
function checkForHighscore(newScore)

    local tempScoreTable = { }

    table.shallowcopy(runtimeScoreTable, tempScoreTable)

    table.insert(tempScoreTable, newScore)
    table.sort(tempScoreTable)

    local trimmedTempScoreTable = { }

    for i=2,11 do
        table.insert(trimmedTempScoreTable, tempScoreTable[i])
    end

    if (trimmedTempScoreTable[1]==runtimeScoreTable[1] and trimmedTempScoreTable[2]==runtimeScoreTable[2] and trimmedTempScoreTable[3]==runtimeScoreTable[3] and trimmedTempScoreTable[4]==runtimeScoreTable[4] and trimmedTempScoreTable[5]==runtimeScoreTable[5] and trimmedTempScoreTable[6]==runtimeScoreTable[6] and trimmedTempScoreTable[7]==runtimeScoreTable[7] and trimmedTempScoreTable[8]==runtimeScoreTable[8] and trimmedTempScoreTable[9]==runtimeScoreTable[9] and trimmedTempScoreTable[10]==runtimeScoreTable[10]) then -- I'm so sorry
        return(nil) -- No new score, the tables match
    else
        runtimeScoreTable = trimmedTempScoreTable
        return(trimmedTempScoreTable) -- tell the calling function that there IS a new highscore
    end

    return(nil) -- We should never get here
end

function updateHighscoreAndName(newScore, name, tempScoreTable)
    local hasAddedName = false

    local tempNameTable = { }
    local trimmedTempNameTable = { }

    table.shallowcopy(runtimeNameTable, tempNameTable)

    for i=1,10 do

        if ((tempScoreTable[i] == newScore) and not hasAddedName) then -- Find the score that matches the new score
            table.insert(tempNameTable, i + 1, name) -- add the name to the temporary table
            hasAddedName = true
        end

    end

    for i=2,11 do
        table.insert(trimmedTempNameTable, tempNameTable[i])
    end

    runtimeNameTable = trimmedTempNameTable

    writeHighscores()
end

function writeHighscores()
    -- Save game data into a table first
    local highScoreData = {
        scoreTable = runtimeScoreTable,
        nameTable = runtimeNameTable,
        reduceFlashing = runtimeReduceFlashing
    }

    -- Serialize game data table into the datastore
    playdate.datastore.write(highScoreData)
end

function writeDefaultHighscores()
    -- Save game data into a table first
    local highScoreData = {
        scoreTable = defaultScoreTable,
        nameTable = defaultNameTable,
        reduceFlashing = runtimeReduceFlashing
    }

    -- Serialize game data table into the datastore
    playdate.datastore.write(highScoreData)
end

function pullHighscores()
    local highScoreData = playdate.datastore.read() -- read the data

    if (highScoreData) then
        if ((highScoreData.nameTable == nil) or (highScoreData.scoreTable == nil)) then
            writeDefaultHighscores() -- Initialize the highscore disk datastore with whatever is in the runtime variables

            local fakeHighScores = { -- Make a fake high score table with the runtime variables
                scoreTable = defaultScoreTable,
                nameTable = defaultNameTable,
                reduceFlashing = runtimeReduceFlashing
            }
        end
        runtimeNameTable = highScoreData.nameTable -- Initialize the runtime copies of the table's internal arrays
        runtimeScoreTable = highScoreData.scoreTable

        return highScoreData -- return the unchanged dataStore for use
    else
        table.shallowcopy(defaultScoreTable, runtimeScoreTable)
        table.shallowcopy(defaultNameTable, runtimeNameTable)

        writeDefaultHighscores() -- Initialize the highscore disk datastore with whatever is in the runtime variables

        local fakeHighScores = { -- Make a fake high score table with the runtime variables
            scoreTable = runtimeScoreTable,
            nameTable = runtimeNameTable,
            reduceFlashing = runtimeReduceFlashing
        }

        return fakeHighScores -- return the faked table in the same format as the real table
    end

end

function formatHighscores()
    local currentFormattedList = ""

    for i=1,10 do
        currentFormattedList = currentFormattedList .. i .. ": " .. runtimeNameTable[i] .. " - " .. runtimeScoreTable[i] .. "\n"
    end

    return currentFormattedList
end

function updateReduceFlashing(newReduceFlashingValue)
    runtimeReduceFlashing = newReduceFlashingValue
    writeHighscores()
end

function resetHighscores()
    table.shallowcopy(defaultScoreTable, runtimeScoreTable)
    table.shallowcopy(defaultNameTable, runtimeNameTable)
    writeHighscores()
end
