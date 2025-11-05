-- You'll want to import these in just about every project you'll work on.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/keyboard"
import "imageCreator"
import "game"
import "otherMath"
import "highscoreUtils"

local gfx <const> = playdate.graphics -- Instead of having to preface all graphics calls with "playdate.graphics", just use "gfx."
local geom = playdate.geometry -- same for geometry

local gameRunning = false

local startTextSprite

local creditTextSprite

local iconSprite
local iconMove = 0

local globeSprite

local highScoreTextSprite

local bgMus

local scrollLocation = 0

local oldIconVer = false
local newIconImage
local oldIconImage

local highScoreNoise

local menu = playdate.getSystemMenu()

local reduceFlashingEffectsMenuItem
local reduceFlashingEffects
local resetHighscoresMenuItem

local keyboardIsSettingHighScore = false
local keyboardTimeout = 0
local newHighscorePoints = 0
local tempHighScoreTable = {}
local pointsFromGame = 0

local highScorePromptSprite
local enterTextSprite
local oldTextEntry

local highscoreListSprite

transitionSprite = nil --       These need to be global for the game
isTransitioning = true -- to be able to trigger a screen transition

local isEndingGame
local isStartingGame
local transitionDirection = -15

local infoCardSprite

function updateHighscoreSprite()

    local highscoreListImage = makeNewFilledRoundRect(gfx.kColorBlack, 300, 400, 5)
    highscoreListImage = drawTextOnImage(highscoreListImage, gfx.kDrawModeFillWhite, formatHighscores(), 20, 5)
    highscoreListSprite:setImage(highscoreListImage)
    highscoreListSprite:moveTo(200, 700) -- Placeholder Location

end

function keyboardCallback()

    enterTextSprite:remove()
    highScorePromptSprite:remove()

    updateHighscoreAndName(newHighscorePoints, playdate.keyboard.text, tempHighScoreTable)

    keyboardIsSettingHighScore = false

    updateHighscoreSprite()

    keyboardTimeout = 3
end

function keyboardChangedCallback()

--     print("CHANGE")

    if (playdate.keyboard.text:len() > 8) then
        playdate.keyboard.text = oldTextEntry
    end

    local enterTextImage = makeNewFilledRoundRect(gfx.kColorWhite, 100, 25, 5)
    enterTextImage = drawTextOnImage(enterTextImage, gfx.kDrawModeFillBlack, playdate.keyboard.text, 8, 5)
    if (enterTextSprite) then
        enterTextSprite:setImage(enterTextImage)
    else
        enterTextSprite = gfx.sprite.new(enterTextImage)
    end
    oldTextEntry = playdate.keyboard.text
end

function keyboardOpenedCallback()
--     print("OPEN")
    iconSprite:moveTo(400, 400)

    local enterTextImage = makeNewFilledRoundRect(gfx.kColorWhite, 100, 25, 5)
    enterTextImage = drawTextOnImage(enterTextImage, gfx.kDrawModeFillBlack, "Player", 8, 5)
    enterTextSprite = gfx.sprite.new(enterTextImage)
    enterTextSprite:moveTo(70, 120)
    enterTextSprite:add()

    scrollLocation = 0
    iconMove = 5
    handleScrolling()

    gfx.sprite.update()
    playdate.timer.updateTimers()
end

function setUp()

    highScoreNoise = playdate.sound.sampleplayer.new("sounds/highscore")

    local startTextImage = makeNewFilledRoundRect(gfx.kColorBlack, 200, 25, 5)
    startTextImage = drawTextOnImage(startTextImage, gfx.kDrawModeFillWhite, "Press A or B to start", 20, 5)
    startTextSprite = gfx.sprite.new(startTextImage)
    startTextSprite:moveTo(200, 220)
    startTextSprite:add()

    local creditTextImage = makeNewFilledRoundRect(gfx.kColorBlack, 150, 25, 5)
    creditTextImage = drawTextOnImage(creditTextImage, gfx.kDrawModeFillWhite, "*Done by Cpucat*", 18, 4)
    creditTextSprite = gfx.sprite.new(creditTextImage)
    creditTextSprite:moveTo(200, -220)
    creditTextSprite:add()

    local highScoreTextImage = makeNewFilledRoundRect(gfx.kColorBlack, 100, 25, 5)
    highScoreTextImage = drawTextOnImage(highScoreTextImage, gfx.kDrawModeFillWhite, "High Scores", 6, 4)
    highScoreTextSprite = gfx.sprite.new(highScoreTextImage)
    highScoreTextSprite:moveTo(200, 270)
    highScoreTextSprite:add()

    newIconImage = gfx.image.new("images/icon")
    assert( newIconImage )
    oldIconImage = gfx.image.new("images/icon_james")
    assert( oldIconImage )

    local globeImage = gfx.image.new("images/globe")
    assert( globeImage )

    local infoCardImage = gfx.image.new("images/infocard")
    assert( infoCardImage )

    infoCardSprite = gfx.sprite.new( infoCardImage )
    infoCardSprite:moveTo(200, -75)
    infoCardSprite:add()

    iconSprite = gfx.sprite.new( newIconImage )
    iconSprite:moveTo( 200, 120 )
    iconSprite:add()
    iconSprite:setZIndex(420) -- "That's the weed number" - CRD, on the dell latitude D420

    globeSprite = gfx.sprite.new(globeImage)
    globeSprite:moveTo(200,120)
    globeSprite:add()
    globeSprite:setZIndex(96) -- am i funny now (also it's inbetween the two values that the icon sprite uses)

    local highScorePromptImage = makeNewFilledRoundRect(gfx.kColorBlack, 170, 50, 5)
    highScorePromptImage = drawTextOnImage(highScorePromptImage, gfx.kDrawModeFillWhite, "New High score!\nPlease enter a name:", 8, 5)
    highScorePromptSprite = gfx.sprite.new(highScorePromptImage)
    highScorePromptSprite:moveTo(90, 80)
    highScorePromptSprite:setZIndex(150)

    local transitionSpriteImage= makeNewFilledRect(gfx.kColorBlack, 800, 240)
    transitionSprite = gfx.sprite.new(transitionSpriteImage)
    transitionSprite:setZIndex(32767)
    transitionSprite:moveTo( 200, 120 )
    transitionSprite:add()

    bgMus = playdate.sound.fileplayer.new("sounds/menu")
    assert( bgMus ) -- Make sure we are actually getting a file back

    bgMus:play(0)

    -- BACKGROUND CREATION
    local backgroundImage = makeNewFilledRect(gfx.kColorBlack, 400, 240)

    -- Add a random amount of "stars"
    for i=0,math.random(50,171) do
        backgroundImage = drawPixelOnImage(backgroundImage, gfx.kColorWhite, math.random(2,398), math.random(2,238))
    end

    gfx.sprite.setBackgroundDrawingCallback( -- THANK YOU
        function( x, y, width, height )      -- PEOPLE WHO
        backgroundImage:draw( 0, 0 )         -- WROTE THE
        end                                  -- SDK DOCUMENTATION
    )

     playdate.keyboard.keyboardWillHideCallback = keyboardCallback
     playdate.keyboard.textChangedCallback = keyboardChangedCallback
     playdate.keyboard.keyboardDidShowCallback = keyboardOpenedCallback

     highscoreListSprite = gfx.sprite.new(highscoreListImage)

     local savedDataTable = pullHighscores()

     reduceFlashingEffects = savedDataTable.reduceFlashing

     updateHighscoreSprite()
     highscoreListSprite:add()

     local error

     reduceFlashingEffectsMenuItem, error = menu:addCheckmarkMenuItem("Less Flicker", reduceFlashingEffects, function(value)
     updateReduceFlashing(value)
     reduceFlashingEffects = value
     end)

     resetHighscoresMenuItem, error = menu:addMenuItem("Reset Scores", function()
     resetHighscores()
     updateHighscoreSprite()
     end)

end

setUp()

function disposeMenuSprites()
    -- REMOVE ALL MENU SPRITES
    startTextSprite:remove()
    iconSprite:remove()
    globeSprite:remove()
    creditTextSprite:remove()
    highScoreTextSprite:remove()

    highscoreListSprite:remove()

    infoCardSprite:remove()

    -- DISCARD MENU ITEMS
    menu:removeMenuItem(reduceFlashingEffectsMenuItem)
    menu:removeMenuItem(resetHighscoresMenuItem)
end

function addMenuSprites()
    -- ADD ALL THE MENU SPRITES
    startTextSprite:add()
    creditTextSprite:add()
    iconSprite:add()
    globeSprite:add()
    highScoreTextSprite:add()
    highscoreListSprite:add()
    infoCardSprite:add()


    -- ADD MENU ITEMS
    local error

    reduceFlashingEffectsMenuItem, error = menu:addCheckmarkMenuItem("Less Flicker", reduceFlashingEffects, function(value)
    updateReduceFlashing(value)
    reduceFlashingEffects = value
    end)

    resetHighscoresMenuItem, error = menu:addMenuItem("Reset Scores", function()
    resetHighscores()
    updateHighscoreSprite()
    end)
end

function startGame()

    game_setUp() -- Run the game's 'set up' function to initialize sprites, sounds, etc

    disposeMenuSprites()

    bgMus:stop() -- Stop the menu music

    gameRunning = true -- Switch the main loop to the "Game" state

    scrollLocation = 0 -- Reset the scroll location
    pointsFromGame = 0 -- Reset the points

end

function endGame()
    gameRunning = false  -- Switch the main loop to the "Menu" state

    -- Dispose all the game sprites
    disposeAllGameObjects()

    -- ADD ALL THE MENU SPRITES
    addMenuSprites()

    bgMus:play(0) -- Play the menu music

    scrollLocation = 0 -- Reset the screen scroll

    local isNewHighscore = checkForHighscore(pointsFromGame)
    if (isNewHighscore) then
        newHighscorePoints = pointsFromGame
        keyboardIsSettingHighScore = true

        tempHighScoreTable = isNewHighscore

        highScoreNoise:play(1)
        highScorePromptSprite:add()
        playdate.keyboard.show("Player")
    end
end

function handleTransition()
    if (not isTransitioning) then
        return
    end

    if ((transitionSprite.x < -400)) then
        isTransitioning = false
    else
        transitionSprite:moveTo(transitionSprite.x + transitionDirection, transitionSprite.y)
    end
end

function handleScrolling()
    -- The section where we handle scrolling

    iconSprite:moveTo((math.cos(iconMove)*105) + 200, (math.sin(iconMove)*25) + 120 + scrollLocation)
    globeSprite:moveTo(200,120 + scrollLocation)
    startTextSprite:moveTo(200, 220 + scrollLocation)
    creditTextSprite:moveTo(200, -220 + scrollLocation)
    highScoreTextSprite:moveTo(200, 270 + scrollLocation)
    highscoreListSprite:moveTo(200, 500 + scrollLocation)
    infoCardSprite:moveTo(200, -75 + scrollLocation)
end

function playdate.update() -- THIS IS WHERE THE MAGIC HAPPENS

    if (isTransitioning) then
        handleTransition()
    end

    if (isStartingGame) then
        gfx.sprite.update()
        playdate.timer.updateTimers()

        if (transitionSprite.x < 0) then
            startGame()
            isStartingGame = false
            return
        end
    end

    if (isEndingGame) then
        gfx.sprite.update()
        playdate.timer.updateTimers()

        if (transitionSprite.x < 29) then
            endGame()
            isEndingGame = false
            return
        end
    end

    if (keyboardIsSettingHighScore or (keyboardTimeout > 0)) then
        gfx.sprite.update()
        playdate.timer.updateTimers()
        keyboardTimeout -= 1
        return
    end

    -- Game State Logic
    if (gameRunning) then
        local gameState = game_update(reduceFlashingEffects) -- Update the game, and store the return value

        if (gameState ~= nil) then -- If the game returned ANYTHING, then we
            isEndingGame = true --    Start the process of ending the game
            pointsFromGame = gameState -- and Save the points from the game
        end
    else

        local change, acceleratedChange = playdate.getCrankChange() -- Poll the crank for scrolling

        scrollLocation += change -- Update the scroll position

        if (playdate.isCrankDocked()) then
            scrollLocation = 0 -- Reset the scroll if we dock the crank for some reason
        end

        scrollLocation = clamp(scrollLocation, -400, 250) -- Make sure to not scroll offscreen

        -- make the logo orbit the globe

        iconMove = ((iconMove + (0.05)) % (2*math.pi))


        -- Do the cool depth thing to the logo

        if (iconMove >= math.pi) then
            iconSprite:setZIndex(69) -- am i funny now
        else
            iconSprite:setZIndex(420) -- "That's the weed number" - CRD, on the dell latitude D420
        end

        local iconScale = 2 * ((math.cos(iconMove + (0.5 * math.pi)) / 2))
        iconScale = clamp(-1 * iconScale,0.1,1)

        -- Add the easter egg switch between the old logo and the new logo
        if (iconMove >= 4.8 and iconMove <= 5) then
            if (math.random(0, 150) == 15) then
                oldIconVer = true
            else
                oldIconVer = false
            end
        end

        if (oldIconVer) then
            iconSprite:setImage(oldIconImage)
            iconSprite:setRotation(0)
            iconSprite:setScale(1)
        else
            iconSprite:setImage(newIconImage)
            iconSprite:setRotation(57.2957795131 * iconMove)
            iconSprite:setScale(iconScale)
        end

        handleScrolling()

        if (not isTransitioning) then
            if (playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonB)) then
                isStartingGame = true
                transitionSprite:moveTo(800, 120)
                isTransitioning = true
                transitionDirection = -40
            end
        end
    end

    gfx.sprite.update()

    -- Per the docs, the crank indicator logic should occur after gfx.sprite.update
    if (playdate.isCrankDocked() and not useTiltControls) then
        playdate.ui.crankIndicator:draw() -- Draw the "USE THE CRANK" image
    end

    playdate.timer.updateTimers()
end
