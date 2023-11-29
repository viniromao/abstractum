local json = require("libraries/dkjson")
local entities = require("mod/entities")

for key, entity in pairs(entities) do
    entities[key].sprite = love.graphics.newImage(entity.sprite)
end

local cursorImage = love.graphics.newImage("assets/cursor.png") -- replace with your cursor image path
customCursor = love.mouse.newCursor("assets/cursor.png", 0, 0)
love.mouse.setCursor(customCursor)

local WINDOW_SIZE = 512
local WINDOW_SIZE_X = 1024
local WINDOW_SIZE_Y = 512
local FRAME_SIZE = 64
local MATRIX_SIZE = (WINDOW_SIZE - FRAME_SIZE) / FRAME_SIZE
local SKIPED_FRAMES = 1


restartButton = {}
restartButton.x = 100
restartButton.y = 100
restartButton.width = 200
restartButton.height = 50
restartButton.text = "Restart"

local initializing = true

local gameOverText = ""

local score = 0
local power = 5

local Entity = {}
local selectedFrames = {}
local originFrame = {}
local originPosition = {}

local frameImage1 = love.graphics.newImage("assets/frame2.png")
local frameImage2 = love.graphics.newImage("assets/frame4.png")
local frameImage3 = love.graphics.newImage("assets/frame.png")
local frameImage4 = love.graphics.newImage("assets/frame3.png")


local isGameOvering = false

frameMatrix = {}
local entitiesArray = {}

local selectedFrameImage = love.graphics.newImage("assets/selectedFrame.png")
local beepSound = love.audio.newSource("assets/selectBeep.mp3", "static")
local updateSound = love.audio.newSource("assets/updateSound.mp3", "static")
local holySound = love.audio.newSource("assets/holySound.mp3", "static")

local logFile = io.open("debug.log", "w")

EffectSideEnum = {
    TOP = "top",
    BOTTOM = "bottom",
    LEFT = "left",
    RIGHT = "right",
    BOTTOM_LEFT = "bottom-left",
    BOTTOM_RIGHT = "bottom-right",
    TOP_LEFT = "top-left",
    TOP_RIGHT = "top-right",
}

function Entity:new(frame, sprite, x, y, sideEffect, name, level)
    local newObj = {
        frameSprite = frame,
        sprite = sprite,
        x = x,
        y = y,
        sideEffect = sideEffect,
        name = name,
        level = level
    }
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end

function love.load()
    logo = love.graphics.newImage("assets/logo.png")
    timer = 0
    duration = 2
    isGameOvering = false
    power = 9
    score = 0
    frameMatrix = {}
    startLogFile()
    setWindowProperties()


    generateEntities()
    updateFrames()
end

function love.update(dt)
    if initializing then
        timer = timer + dt
    end
    if timer >= duration then
        -- Perform your action here
        print("Timer finished!")
        initializing = false
        -- Optionally, reset or stop the timer
        timer = 0 -- Resetting the timer
    end
end

function love.draw()
    love.graphics.scale(1, 1)

    if initializing then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local imageWidth = logo:getWidth()
        local imageHeight = logo:getHeight()

        local scaleX = 0.50 -- 50% of the original width
        local scaleY = 0.50 -- 50% of the original height

        -- Adjust position to center the scaled image
        local x = (screenWidth / 2) - (imageWidth * scaleX / 2)
        local y = (screenHeight / 2) - (imageHeight * scaleY / 2)

        love.graphics.draw(logo, x, y, 0, scaleX, scaleY)
    else
        drawMap()
    end
end

function love.quit()
    if (logFile ~= nil) then
        logFile:close()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        beepSound:play()
        for index, line in pairs(frameMatrix) do
            for index2, frame in pairs(line) do
                if frame ~= nil then
                    if x >= frame.x and x <= frame.x + FRAME_SIZE and
                        y >= frame.y and y <= frame.y + FRAME_SIZE then
                        if not isGameOvering then
                            getEffectSide(index, index2, frame)
                        end
                    end
                end
            end
        end
    end

    if button == 2 then
        for indexY, line in pairs(frameMatrix) do
            for indexX, frame in pairs(line) do
                if frame ~= nil then
                    if x >= frame.x and x <= frame.x + FRAME_SIZE and
                        y >= frame.y and y <= frame.y + FRAME_SIZE then
                        if not isGameOvering then
                            for something, selectedFrame in pairs(selectedFrames) do
                                if (selectedFrame.x == indexX and selectedFrame.y == indexY) or (originPosition.x == indexX and originPosition.y == indexY and originFrame.name == "sun") then
                                    executeEffect(selectedFrame.x, selectedFrame.y, originFrame)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        -- If the Escape key was pressed, close the application
        love.event.quit()
    end

    if key == "r" then
        -- If the Escape key was pressed, close the application
        love.load()
    end
end

function startLogFile()
    do
        local oldPrint = print

        function print(...)
            local output = ""
            for i, v in ipairs({ ... }) do
                output = output .. tostring(v) .. "\t"
            end
            if (logFile ~= nil) then
                logFile:write(output .. "\n")
                logFile:flush()
                oldPrint(...)
            end
        end
    end
end

function setWindowProperties()
    gameFont = love.graphics.newFont("assets/font2.ttf", 15)
    GUIFont = love.graphics.newFont("assets/fontBeauty.ttf", 25)
    titleFont = love.graphics.newFont("assets/fontBeauty.ttf", 50)

    math.randomseed(os.time())
    local icon = love.image.newImageData("assets/icon.png")
    love.window.setIcon(icon)
    love.window.setMode(WINDOW_SIZE, WINDOW_SIZE)
    love.window.setTitle("Abstractum")
end

function generateEntities()
    local frame = love.graphics.newImage("assets/frame.png")

    entitiesArray = mapToArray(entities)

    for i = 1, MATRIX_SIZE do
        frameMatrix[i] = {}
        for j = 1, MATRIX_SIZE
        do
            local randomIndex = math.random(1, #entitiesArray)
            local x = ((j - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                ((WINDOW_SIZE % FRAME_SIZE) / 2)
            local y = ((i - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                ((WINDOW_SIZE % FRAME_SIZE) / 2)
            frameMatrix[i][j] = Entity:new(frame, entities[entitiesArray[randomIndex].key].sprite, x, y,
                entities[entitiesArray[randomIndex].key].sideEffect, entitiesArray[randomIndex].key, randomizeLevels())
        end
    end
end

function drawMap()
    if isGameOvering then
        love.graphics.setFont(titleFont)
        local text = "Game Over"


        local windowWidth = love.graphics.getWidth()
        local windowHeight = love.graphics.getHeight()

        -- Get the width and height of the text
        local textWidth = titleFont:getWidth(text)
        local textHeight = titleFont:getHeight()

        -- Calculate the position
        local x = (windowWidth / 2) - (textWidth / 2)
        local y = (windowHeight / 2) - (textHeight / 2)

        local windowWidthSub = love.graphics.getWidth()
        local windowHeightSub = love.graphics.getHeight()

        -- Get the width and height of the text
        local textWidthSub = titleFont:getWidth(gameOverText)
        local textHeightSub = titleFont:getHeight()

        -- Calculate the position
        local xSub = (windowWidthSub / 2) - (textWidthSub / 2)
        local ySub = (windowHeightSub / 2) - (textHeightSub / 2)

        -- Draw the text
        love.graphics.print(text, x, y - 100)
        love.graphics.print(gameOverText, xSub, ySub + 20)
    else
        love.graphics.setFont(GUIFont)
        love.graphics.print("Score: " .. score, 20, 0)
        love.graphics.print("Power: " .. power, 120, 0)


        for i = SKIPED_FRAMES, MATRIX_SIZE do
            for j = SKIPED_FRAMES, MATRIX_SIZE do
                if (frameMatrix[i] ~= nil and frameMatrix[i][j] ~= nil) then
                    local entity = frameMatrix[i][j]
                    love.graphics.draw(entity.frameSprite, entity.x, entity.y)
                    love.graphics.draw(entity.sprite, entity.x + FRAME_SIZE / 4, entity.y + FRAME_SIZE / 4 + 4)
                    love.graphics.setFont(gameFont)

                    if entity.level < 10 then
                        love.graphics.print(entity.level, entity.x + 30, entity.y - 2)
                    else
                        love.graphics.print(entity.level, entity.x + 27, entity.y - 2)
                    end
                end
            end
        end

        if selectedFrames ~= {} then
            for key, selectedFrame in pairs(selectedFrames) do
                love.graphics.draw(selectedFrameImage, frameMatrix[selectedFrame.y][selectedFrame.x].x,
                    frameMatrix[selectedFrame.y][selectedFrame.x].y)
            end
        end

        -- for key, entity in pairs(entities) do
        --     love.graphics.draw(entity.sprite, entity.x, entity.y)
        --     -- Optionally draw frameSprite or perform other operations
        -- end
    end
end

function mapToArray(map)
    local array = {}
    for key, value in pairs(map) do
        -- Check if the value is a table and it's used as an array
        if type(value) == "table" and #value > 0 then
            local subarray = {}
            for i, v in ipairs(value) do
                table.insert(subarray, v)
            end
            table.insert(array, { key = key, value = subarray })
        else
            table.insert(array, { key = key, value = value })
        end
    end
    return array
end

function draftEffect()

end

function getEffectSide(i, j, entity)
    if entity.name == "questionMark" then
        print("questionMark ui")
        originFrame = entity
        originPosition = { x = j, y = i }
        executeEffect(j, i, entity)
        return
    end

    if entity.sideEffect == nil then
        selectedFrames = {}
        print(entity.name .. "entity has an empty sideEffect")
        return
    end

    local array = {}

    for index, location in ipairs(entity.sideEffect) do
        print(index, location)

        if location == EffectSideEnum.BOTTOM then
            if (frameMatrix[i + 1] ~= nil and frameMatrix[i + 1][j] ~= nil) then
                table.insert(array, { y = i + 1, x = j })
            end
        end

        if location == EffectSideEnum.TOP then
            if (frameMatrix[i - 1] ~= nil and frameMatrix[i - 1][j] ~= nil) then
                table.insert(array, { y = i - 1, x = j })
            end
        end

        if location == EffectSideEnum.RIGHT then
            if (frameMatrix[i][j + 1] ~= nil) then
                table.insert(array, { y = i, x = j + 1 })
            end
        end

        if location == EffectSideEnum.LEFT then
            if (frameMatrix[i][j - 1] ~= nil) then
                table.insert(array, { y = i, x = j - 1 })
            end
        end

        if location == EffectSideEnum.TOP_RIGHT then
            if (frameMatrix[i - 1] ~= nil and frameMatrix[i - 1][j + 1] ~= nil) then
                table.insert(array, { y = i - 1, x = j + 1 })
            end
        end

        if location == EffectSideEnum.TOP_LEFT then
            if (frameMatrix[i - 1] ~= nil and frameMatrix[i - 1][j - 1] ~= nil) then
                table.insert(array, { y = i - 1, x = j - 1 })
            end
        end

        if location == EffectSideEnum.BOTTOM_LEFT then
            if (frameMatrix[i + 1] ~= nil and frameMatrix[i + 1][j - 1] ~= nil) then
                table.insert(array, { y = i + 1, x = j - 1 })
            end
        end

        if location == EffectSideEnum.BOTTOM_RIGHT then
            if (frameMatrix[i + 1] ~= nil and frameMatrix[i + 1][j + 1] ~= nil) then
                table.insert(array, { y = i + 1, x = j + 1 })
            end
        end
    end
    selectedFrames = array
    originFrame = entity
    originPosition = { x = j, y = i }
end

function executeEffect(selectedFrameX, selectedFrameY, frame)
    if frame == nil then
        return
    end

    if (frame.name == "tree") then
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[selectedFrameY][selectedFrameX].level +
            originFrame.level
        removeFrame(originPosition.x, originPosition.y)
        updateSound:play()
        consumePower()
    end


    if (frame.name == "arrow") then
        if frameMatrix[selectedFrameY][selectedFrameX].name ~= "death" then
            local randomIndex = math.random(1, #entitiesArray)

            frameMatrix[selectedFrameY][selectedFrameX].sprite = entities[entitiesArray[randomIndex].key].sprite
            frameMatrix[selectedFrameY][selectedFrameX].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
            frameMatrix[selectedFrameY][selectedFrameX].name = entitiesArray[randomIndex].key
            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end


    if (frame.name == "bell") then
        local valueToBeDistributed = frameMatrix[selectedFrameY][selectedFrameX].level + originFrame.level
        local distribute1 = math.floor(valueToBeDistributed / 2)
        local distribute2 = math.floor(valueToBeDistributed / 2) + valueToBeDistributed % 2
        local firstAssertion = true

        for index, selectedFrame in pairs(selectedFrames) do
            if (selectedFrame.x ~= selectedFrameX or selectedFrame.y ~= selectedFrameY) then
                if firstAssertion then
                    frameMatrix[selectedFrame.y][selectedFrame.x].level = frameMatrix[selectedFrame.y][selectedFrame.x]
                        .level + distribute1
                    firstAssertion = false
                else
                    frameMatrix[selectedFrame.y][selectedFrame.x].level = frameMatrix[selectedFrame.y][selectedFrame.x]
                        .level + distribute2
                end
            end
        end

        removeFrame(originPosition.x, originPosition.y)
        removeFrame(selectedFrameX, selectedFrameY)
        updateSound:play()
        consumePower()
    end


    if (frame.name == "chain") then
        if frameMatrix[selectedFrameY][selectedFrameX].name == "chain" then
            frameMatrix[selectedFrameY][selectedFrameX].level = (frameMatrix[originPosition.y][originPosition.x].level + frameMatrix[selectedFrameY][selectedFrameX].level) *
                2
            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end


    if (frame.name == "checkMark") then
        power = power + frameMatrix[originPosition.y][originPosition.x].level +
            frameMatrix[selectedFrameY][selectedFrameX].level
        updateSound:play()
        removeFrame(originPosition.x, originPosition.y)
        consumePower()
    end


    if (frame.name == "cross") then
        score = score + frameMatrix[selectedFrameY][selectedFrameX].level
        holySound:play()
        removeFrame(originPosition.x, originPosition.y)
        consumePower()
    end


    if (frame.name == "death") then

    end


    if (frame.name == "droplet") then
        if frameMatrix[selectedFrameY][selectedFrameX].name ~= "death" then
            local randomIndex = math.random(1, #entitiesArray)

            frameMatrix[selectedFrameY][selectedFrameX].sprite = entities[entitiesArray[randomIndex].key].sprite
            frameMatrix[selectedFrameY][selectedFrameX].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
            frameMatrix[selectedFrameY][selectedFrameX].name = entitiesArray[randomIndex].key
            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end


    if (frame.name == "earth") then
        local randomBonus = math.random(-1, 2)
        local finalBonus

        if randomBonus >= 0 then
            finalBonus = randomBonus + frameMatrix[originPosition.y][originPosition.x].level
        else
            finalBonus = randomBonus - frameMatrix[originPosition.y][originPosition.x].level
        end
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[selectedFrameY][selectedFrameX].level +
            finalBonus
        if frameMatrix[selectedFrameY][selectedFrameX].level <= 0 then
            removeFrame(selectedFrameX, selectedFrameY)
        end
        removeFrame(originPosition.x, originPosition.y)

        updateSound:play()
        consumePower()
    end


    if (frame.name == "exclamationMark") then
        if #selectedFrames == 2 then
            local otherSelection = removeElementAndCopy(selectedFrames, selectedFrameX, selectedFrameY)[1]

            local tempSprite = frameMatrix[selectedFrameY][selectedFrameX].sprite
            local tempSideEffect = frameMatrix[selectedFrameY][selectedFrameX].sideEffect
            local tempName = frameMatrix[selectedFrameY][selectedFrameX].name
            local tempLevel = frameMatrix[selectedFrameY][selectedFrameX].level +
                frameMatrix[originPosition.y][originPosition.x].level

            frameMatrix[selectedFrameY][selectedFrameX].sprite = frameMatrix[otherSelection.y][otherSelection.x].sprite
            frameMatrix[selectedFrameY][selectedFrameX].sideEffect = frameMatrix[otherSelection.y][otherSelection.x]
                .sideEffect
            frameMatrix[selectedFrameY][selectedFrameX].name = frameMatrix[otherSelection.y][otherSelection.x].name
            frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[otherSelection.y][otherSelection.x].level

            frameMatrix[otherSelection.y][otherSelection.x].sprite = tempSprite
            frameMatrix[otherSelection.y][otherSelection.x].sideEffect = tempSideEffect
            frameMatrix[otherSelection.y][otherSelection.x].name = tempName
            frameMatrix[otherSelection.y][otherSelection.x].level = tempLevel

            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end


    if (frame.name == "fire") then
        score = score + frameMatrix[selectedFrameY][selectedFrameX].level +
            frameMatrix[originPosition.y][originPosition.x].level
        updateSound:play()
        removeFrame(originPosition.x, originPosition.y)
        removeFrame(selectedFrameX, selectedFrameY)
        consumePower()
    end


    if (frame.name == "gate") then
        frameMatrix[selectedFrameY][selectedFrameX].sprite = entities["cross"].sprite
        frameMatrix[selectedFrameY][selectedFrameX].sideEffect = entities["cross"].sideEffect
        frameMatrix[selectedFrameY][selectedFrameX].name = "cross"
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[selectedFrameY][selectedFrameX].level +
            frameMatrix[originPosition.y][originPosition.x].level

        updateSound:play()
        removeFrame(originPosition.x, originPosition.y)
        consumePower()
    end


    if (frame.name == "hammer") then
        frameMatrix[originPosition.y][originPosition.x].level = frameMatrix[originPosition.y][originPosition.x].level + 1
        removeFrame(selectedFrameX, selectedFrameY)
        updateSound:play()
        consumePower()
    end


    if (frame.name == "hearth") then
        if frameMatrix[selectedFrameY][selectedFrameX].name == "shield" then
            frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[originPosition.y][originPosition.x].level * 2 +
                frameMatrix[selectedFrameY][selectedFrameX].level
        else
            frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[originPosition.y][originPosition.x].level +
                frameMatrix[selectedFrameY][selectedFrameX].level
        end

        removeFrame(originPosition.x, originPosition.y)
        updateSound:play()
        consumePower()
    end


    if (frame.name == "moon") then
        local otherSelections = removeElementAndCopy(selectedFrames, selectedFrameX, selectedFrameY)

        local sum = 0

        removeFrame(originPosition.x, originPosition.y)

        for key, otherSelection in pairs(otherSelections) do
            sum = sum + frameMatrix[otherSelection.y][otherSelection.x].level
            removeFrame(otherSelection.x, otherSelection.y)
        end

        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[selectedFrameY][selectedFrameX].level + sum +
            originFrame.level

        updateSound:play()
        consumePower()
    end


    if (frame.name == "potion") then
        local randomIndex = math.random(1, 2)

        if randomIndex == 1 then
            score = score + frameMatrix[selectedFrameY][selectedFrameX].level
        else
            score = score + frameMatrix[originPosition.y][originPosition.x].level
        end

        updateSound:play()
        removeFrame(originPosition.x, originPosition.y)
        consumePower()
    end


    if (frame.name == "questionMark") then
        local incompleteRows = getIncompleteRows()


        for i = 1, 3, 1 do
            if #incompleteRows > 0 then
                local randomRow = incompleteRows[math.random(1, #incompleteRows)]

                local newFrame = love.graphics.newImage("assets/frame.png")

                local randomIndex = math.random(1, #entitiesArray)
                local x = ((#frameMatrix[randomRow] - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                    ((WINDOW_SIZE % FRAME_SIZE) / 2)
                local y = ((i - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                    ((WINDOW_SIZE % FRAME_SIZE) / 2)
                table.insert(frameMatrix[randomRow],
                    Entity:new(newFrame, entities[entitiesArray[randomIndex].key].sprite, x, y,
                        entities[entitiesArray[randomIndex].key].sideEffect, entitiesArray[randomIndex].key,
                        randomizeLevels() + frameMatrix[originPosition.y][originPosition.x].level))
                incompleteRows = getIncompleteRows()

                -- frameMatrix[i][j] = Entity:new(newFrame, entities[entitiesArray[randomIndex].key].sprite, x, y,
                -- entities[entitiesArray[randomIndex].key].sideEffect, entitiesArray[randomIndex].key, 1)

                print("randomRow: " .. randomRow)
                print("row size: " .. #frameMatrix[randomRow])
            end
        end


        removeFrame(originPosition.x, originPosition.y)
        updateSound:play()
        consumePower()
    end

    if (frame.name == "spear") then
        frameMatrix[selectedFrameY][selectedFrameX].sprite = frameMatrix[originPosition.y][originPosition.x].sprite
        frameMatrix[selectedFrameY][selectedFrameX].sideEffect = frameMatrix[originPosition.y][originPosition.x]
            .sideEffect
        frameMatrix[selectedFrameY][selectedFrameX].name = frameMatrix[originPosition.y][originPosition.x].name
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[originPosition.y][originPosition.x].level +
            frameMatrix[selectedFrameY][selectedFrameX].level

        removeFrame(originPosition.x, originPosition.y)
        updateSound:play()
        consumePower()
    end

    if (frame.name == "sun") then
        if originFrame.name == "sun" then
            for index, selectedFrame in pairs(selectedFrames) do
                frameMatrix[selectedFrame.y][selectedFrame.x].level = frameMatrix[selectedFrame.y][selectedFrame.x]
                    .level + originFrame.level
            end

            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end

    if (frame.name == "sword") then
        if frameMatrix[selectedFrameY][selectedFrameX].name == "death" then
            local randomIndex = math.random(1, #entitiesArray)

            frameMatrix[selectedFrameY][selectedFrameX].sprite = entities[entitiesArray[randomIndex].key].sprite
            frameMatrix[selectedFrameY][selectedFrameX].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
            frameMatrix[selectedFrameY][selectedFrameX].name = entitiesArray[randomIndex].key
            removeFrame(originPosition.x, originPosition.y)
            updateSound:play()
            consumePower()
        end
    end

    if (frame.name == "time") then
        score = score + frameMatrix[selectedFrameY][selectedFrameX].level +
            frameMatrix[originPosition.y][originPosition.x].level
        updateSound:play()
        local randomIndex = math.random(1, #entitiesArray)

        frameMatrix[selectedFrameY][selectedFrameX].sprite = entities[entitiesArray[randomIndex].key].sprite
        frameMatrix[selectedFrameY][selectedFrameX].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
        frameMatrix[selectedFrameY][selectedFrameX].name = entitiesArray[randomIndex].key

        local randomIndex = math.random(1, #entitiesArray)

        frameMatrix[originPosition.y][originPosition.x].sprite = entities[entitiesArray[randomIndex].key].sprite
        frameMatrix[originPosition.y][originPosition.x].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
        frameMatrix[originPosition.y][originPosition.x].name = entitiesArray[randomIndex].key
        consumePower()
    end

    if (frame.name == "shield") then
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[originPosition.y][originPosition.x].level +
            frameMatrix[selectedFrameY][selectedFrameX].level
        local randomIndex = math.random(1, #entitiesArray)

        frameMatrix[originPosition.y][originPosition.x].sprite = entities[entitiesArray[randomIndex].key].sprite
        frameMatrix[originPosition.y][originPosition.x].sideEffect = entities[entitiesArray[randomIndex].key].sideEffect
        frameMatrix[originPosition.y][originPosition.x].name = entitiesArray[randomIndex].key

        updateSound:play()
        consumePower()
    end

    if (frame.name == "walls") then
        power = power + frameMatrix[selectedFrameY][selectedFrameX].level +
            frameMatrix[originPosition.y][originPosition.x].level

        updateSound:play()
        removeFrame(originPosition.x, originPosition.y)
        consumePower()
    end

    if (frame.name == "wind") then
        local tempSprite = frameMatrix[selectedFrameY][selectedFrameX].sprite
        local tempSideEffect = frameMatrix[selectedFrameY][selectedFrameX].sideEffect
        local tempName = frameMatrix[selectedFrameY][selectedFrameX].name
        local tempLevel =
            frameMatrix[originPosition.y][originPosition.x].level

        frameMatrix[selectedFrameY][selectedFrameX].sprite = frameMatrix[originPosition.y][originPosition.x].sprite
        frameMatrix[selectedFrameY][selectedFrameX].sideEffect = frameMatrix[originPosition.y][originPosition.x]
            .sideEffect
        frameMatrix[selectedFrameY][selectedFrameX].name = frameMatrix[originPosition.y][originPosition.x].name
        frameMatrix[selectedFrameY][selectedFrameX].level = frameMatrix[originPosition.y][originPosition.x].level

        frameMatrix[originPosition.y][originPosition.x].sprite = tempSprite
        frameMatrix[originPosition.y][originPosition.x].sideEffect = tempSideEffect
        frameMatrix[originPosition.y][originPosition.x].name = tempName
        frameMatrix[originPosition.y][originPosition.x].level = tempLevel

        updateSound:play()
        consumePower()
    end

    if (frame.name == "x") then
        updateSound:play()

        removeFrame(originPosition.x, originPosition.y)
        removeFrame(selectedFrameX, selectedFrameY)
        consumePower()
    end

    selectedFrames = {}
    originFrame = {}
    originPosition = {}
    updateFrames()
end

function removeFrame(x, y)
    if frameMatrix[y] then
        table.remove(frameMatrix[y], x)
    end

    if #frameMatrix[y] == 0 then
        table.remove(frameMatrix, y)
    end

    reorganizeFrames()
end

function getFrame(i, j)
    return frameMatrix[i][j]
end

function reorganizeFrames()
    for i = 1, MATRIX_SIZE do
        for j = 1, MATRIX_SIZE
        do
            if (frameMatrix[i] ~= nil and frameMatrix[i][j] ~= nil) then
                local x = ((j - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                    ((WINDOW_SIZE % FRAME_SIZE) / 2)
                local y = ((i - SKIPED_FRAMES) * FRAME_SIZE) + (SKIPED_FRAMES * FRAME_SIZE / 2) +
                    ((WINDOW_SIZE % FRAME_SIZE) / 2)

                frameMatrix[i][j].x = x
                frameMatrix[i][j].y = y
            end
        end
    end
end

function removeElementAndCopy(array, xValue, yValue)
    local newArray = {}
    for i, v in ipairs(array) do
        if not (v.x == xValue and v.y == yValue) then
            table.insert(newArray, v)
        end
    end
    return newArray
end

function printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. ": ")
            printTable(value, indent .. "  ")
        else
            print(indent .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

function consumePower()
    power = power - 1

    if power <= 0 then
        gameOver("You ran out of Power")
    end
end

function gameOver(text)
    isGameOvering = true
    gameOverText = text .. "\n Press 'R' To Restart"
end

function getIncompleteRows()
    local incompleteRows = {}

    for index = 1, MATRIX_SIZE, 1 do
        if #frameMatrix[index] < MATRIX_SIZE then
            print("row: " .. index .. "   " .. #frameMatrix[index] .. "<" .. MATRIX_SIZE)
            table.insert(incompleteRows, index)
        end
    end

    return incompleteRows
end

function upgrade(x, y, levelSum)
    frameMatrix[y][x].level = frameMatrix[y][x].level + levelSum
end

function updateFrames()
    for row, frameRow in pairs(frameMatrix) do
        for column, currentFrame in pairs(frameRow) do
            print("currentFrame.level: " .. currentFrame.level)

            if (currentFrame.level < 2) then
                frameMatrix[row][column].frameSprite = frameImage1
            end

            if (currentFrame.level >= 2 and currentFrame.level < 3) then
                frameMatrix[row][column].frameSprite = frameImage2
            end

            if (currentFrame.level >= 3 and currentFrame.level < 5) then
                frameMatrix[row][column].frameSprite = frameImage3
            end

            if (currentFrame.level >= 5) then
                frameMatrix[row][column].frameSprite = frameImage4
            end
        end
    end
end

function randomizeLevels()
    local randomLevel = math.random(100) -- Generate a random number between 1 and 100
    if randomLevel <= 50 then
        return 1                         -- 50% chance for 1
    elseif randomLevel <= 80 then
        return 2                         -- Additional 30% chance for 2
    else
        return 3                         -- Remaining 20% chance for 3
    end
end
