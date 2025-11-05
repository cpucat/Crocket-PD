-- You'll want to import these in just about every project you'll work on.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "imageCreator"
import "otherMath"
import "gameUtils"
import "deathQuotes"

local gfx <const> = playdate.graphics -- Instead of having to preface all graphics calls with "playdate.graphics", just use "gfx."
local geom = playdate.geometry -- same for geometry

local bgMus

local running

local damagesprite
local damageimage

local playerRotation

local currentCrankVel
local crankPercentage

local chargeBarBackground
local chargeBarWhiteBackground
local chargeBarValue
local chargeBarCover

local runPlayerDamage
local playerDamageTimer
local playerDeathCompleted

local playerSprite
local playerVelY

local movingBarSpriteOneT
local movingBarSpriteOneB
local movingBarSpriteTwoT
local movingBarSpriteTwoB

local lastY

local points
local pointTimerRunning
local pointTimer
local scoreSprite
local scoreBackgroundImage
local scoreBackgroundSprite

local barSpeed

local gameBGM
local crashBGM

local playerAnimation

local multiplierSprite
local multiplierInverseSprite
local currentMultiplier
local multiplierInPlay
local currentMultiplierBarSet
local currentMultiplierSprite

local multiplierLoseSFX
local multiplierAddSFX

local hasAppliedVhsEffect

local poleImageTableLength
local movingBarImages

local explodeSFX

local TAGS = {
    player = 1,
    obstacle = 2,
    multiplier = 3
}

local deathQuoteString

function randomizeBars(barNumber, xPos)
    lastY = lastY + math.random(-70, 70)
    lastY = clamp(lastY, -100, 100)

    if (barNumber == 1) then
        movingBarSpriteOneT:moveTo(xPos, lastY)
        movingBarSpriteOneB:moveTo(xPos, lastY + math.random(260, 280))
        movingBarSpriteOneT:setImage(movingBarImages:getImage(math.random(1,poleImageTableLength)))
        movingBarSpriteOneB:setImage(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    end
    if (barNumber == 2) then
        movingBarSpriteTwoT:moveTo(xPos, lastY)
        movingBarSpriteTwoB:moveTo(xPos, lastY + math.random(260, 280)) movingBarSpriteTwoT:setImage(movingBarImages:getImage(math.random(1,poleImageTableLength)))
        movingBarSpriteTwoB:setImage(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    end
end

function moveBars(speed)
    movingBarSpriteOneT:moveTo(movingBarSpriteOneT.x - speed, movingBarSpriteOneT.y)
    movingBarSpriteOneB:moveTo(movingBarSpriteOneB.x - speed, movingBarSpriteOneB.y)

    movingBarSpriteTwoT:moveTo(movingBarSpriteTwoT.x - speed, movingBarSpriteTwoT.y)
    movingBarSpriteTwoB:moveTo(movingBarSpriteTwoB.x - speed, movingBarSpriteTwoB.y)

    if (movingBarSpriteOneT.x <= 0) then
        randomizeBars(1, 450)
        randomizeMultiplierSprite(1)
    end
    if (movingBarSpriteTwoT.x <= 0) then
        randomizeBars(2, 450)
        randomizeMultiplierSprite(2)
    end
end

function randomizeMultiplierSprite(barSet)
    if (multiplierInPlay) then
        return nil
    end

    if (math.random(1,6) ~= 5) then
        return nil
    end

    -- 112 is halfway between both bars
    if (barSet == 1) then
        multiplierSprite:moveTo(movingBarSpriteOneT.x + 112, clamp((math.random(1,2) * 2 - 3) * -200, 60, 220))
    else
        if (barSet == 2) then
            multiplierSprite:moveTo(movingBarSpriteTwoT.x + 112, clamp((math.random(1,2) * 2 - 3) * -200, 60, 220))
        end
    end

    multiplierInPlay = true

end

function handleMultiplierSprite(speed)
    if (multiplierSprite.x >= -10) then
        multiplierSprite:moveTo(multiplierSprite.x - speed, multiplierSprite.y)
    else
        multiplierInPlay = false
        if (multiplierSprite.y ~= -40) then
            if (currentMultiplier ~= 1) then
                multiplierLoseSFX:play()
            end
            currentMultiplier = 1
            currentMultiplierSprite:remove()
            multiplierSprite:moveTo(-10, -40)
        end
    end

    multiplierInverseSprite:moveTo(multiplierSprite.x, multiplierSprite.y)
    multiplierInverseSprite:setRotation((multiplierInverseSprite:getRotation() + 1) % 360)
end

function increaseMultiplier()
    if (currentMultiplier == 1) then
        currentMultiplier += 1
    else
        currentMultiplier *= 2
    end

    local multiplierTextImage = makeNewFilledRect(gfx.kColorBlack, 200, 25, 5)
    multiplierTextImage = drawTextOnImage(multiplierTextImage, gfx.kDrawModeFillWhite, "Multiplier: " .. currentMultiplier, 6, 6)
    currentMultiplierSprite:setImage(multiplierTextImage)

    multiplierAddSFX:play()
end

function game_setUp()

    -- Initialize a bunch of variables
    running = true
    playerRotation = 0
    currentCrankVel = -170
    crankPercentage = 0
    runPlayerDamage = 0
    playerDamageTimer = 20
    playerDeathCompleted = false
    playerVelY = 0
    points = 0
    pointTimerRunning = false
    barSpeed = 2
    lastY = math.random(-100, 100)
    multiplierInPlay = false
    currentMultiplier = 1
    currentMultiplierBarSet = 0
    hasAppliedVhsEffect = false

    local multiplierImage = gfx.image.new("images/multiplier")
    assert( multiplierImage )

    local multiplierInverseImage = gfx.image.new("images/multiplierinverse")
    assert( multiplierInverseImage )

    local playerImages = gfx.imagetable.new("images/player")
    assert( playerImages )

    playerAnimation = gfx.animation.loop.new(100, playerImages, true)

    gameBGM = playdate.sound.fileplayer.new("sounds/gameBGM")
    assert(gameBGM)

    crashBGM = playdate.sound.fileplayer.new("sounds/crash")
    assert(crashBGM)

    explodeSFX = playdate.sound.sampleplayer.new("sounds/explosion")
    assert(explodeSFX)

    multiplierAddSFX = playdate.sound.sampleplayer.new("sounds/multiplierGain")
    assert(multiplierAddSFX)

    multiplierLoseSFX = playdate.sound.sampleplayer.new("sounds/multiplierLost")
    assert(multiplierLoseSFX)

    playerSprite = gfx.sprite.new(playerAnimation:image())
    playerSprite:moveTo( 200, 120 ) -- center the player sprite
    playerSprite:add() -- actually display the player
    playerSprite:setCollideRect(8, 6, 35, 18)
    playerSprite:setZIndex(32758)
    playerSprite:setTag(TAGS.player)
    playerSprite.update = function()
        playerSprite:setImage(playerAnimation:image())
        if not playerAnimation:isValid() then
            playerSprite.update:remove()
        end
    end

    local damageimage = gfx.image.new(400,240,gfx.kColorBlack) -- make a new black image

    damagesprite = gfx.sprite.new( damageimage ) -- set up the damage indicator sprite
    damagesprite:moveTo( 200, 120 ) -- (200,120 is centered on screen, 228,120 is centered to device)
    damagesprite:setIgnoresDrawOffset(true) -- Ignore camera movement
    damagesprite:setZIndex(32765)

    chargeBarBackground = gfx.sprite.new(makeNewFilledRoundRect(gfx.kColorBlack, 40, 240, 5)) --Make the charge bar
    chargeBarBackground:moveTo(0,120)
    chargeBarBackground:add()
    chargeBarBackground:setIgnoresDrawOffset(true)
    chargeBarBackground:setZIndex(32762)

    chargeBarWhiteBackground = gfx.sprite.new(makeNewFilledRoundRect(gfx.kColorWhite, 50, 244, 5)) --Make the charge bar
    chargeBarWhiteBackground:moveTo(0,120)
    chargeBarWhiteBackground:add()
    chargeBarWhiteBackground:setIgnoresDrawOffset(true)
    chargeBarWhiteBackground:setZIndex(32759)

    chargeBarValue = gfx.sprite.new(makeNewFilledRoundRect(gfx.kColorWhite, 30, 230, 5)) --Make the charge bar value indicator
    chargeBarValue:moveTo(0,120)
    chargeBarValue:setIgnoresDrawOffset(true)
    chargeBarValue:setZIndex(32763)

    chargeBarCover = gfx.sprite.new(makeNewFilledRect(gfx.kColorBlack, 30, 10)) --Make the charge bar value indicator cover
    chargeBarCover:moveTo(0,120)
    chargeBarCover:setIgnoresDrawOffset(true)
    chargeBarCover:setZIndex(32764)

    multiplierSprite = gfx.sprite.new(multiplierImage)
    multiplierSprite:moveTo( 562, clamp((math.random(1,2) * 2 - 3) * -200, 60, 220))
    multiplierSprite:add()
    multiplierSprite:setCollideRect(4, 4, 29, 29)
    multiplierSprite:setTag(TAGS.multiplier)
    multiplierInPlay = true
    multiplierSprite:setZIndex(15)

    multiplierInverseSprite = gfx.sprite.new(multiplierInverseImage)
    multiplierInverseSprite:add()
    multiplierInverseSprite:moveTo( 562, 0)
    multiplierInverseSprite:setZIndex(32761)
    multiplierInverseSprite:setImageDrawMode(gfx.kDrawModeNXOR)

    currentMultiplierSprite = gfx.sprite.new()
    currentMultiplierSprite:moveTo(300,9)
    currentMultiplierSprite:setZIndex(32760)

    chargeBarValue:add()
    chargeBarCover:add()

    movingBarImages = gfx.imagetable.new("images/pole")
    assert( movingBarImages )

    poleImageTableLength = movingBarImages:getLength()


    movingBarSpriteOneT = gfx.sprite.new(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    movingBarSpriteOneB = gfx.sprite.new(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    movingBarSpriteTwoT = gfx.sprite.new(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    movingBarSpriteTwoB = gfx.sprite.new(movingBarImages:getImage(math.random(1,poleImageTableLength)))
    movingBarSpriteOneT:add()
    movingBarSpriteOneB:add()
    movingBarSpriteTwoT:add()
    movingBarSpriteTwoB:add()
    movingBarSpriteOneT:setCollideRect(6, 5, 10, 190)
    movingBarSpriteOneB:setCollideRect(6, 5, 10, 190)
    movingBarSpriteTwoT:setCollideRect(6, 5, 10, 190)
    movingBarSpriteTwoB:setCollideRect(6, 5, 10, 190)
    movingBarSpriteOneT:setTag(TAGS.obstacle)
    movingBarSpriteOneB:setTag(TAGS.obstacle)
    movingBarSpriteTwoT:setTag(TAGS.obstacle)
    movingBarSpriteTwoB:setTag(TAGS.obstacle)

    scoreBackgroundImage = makeNewFilledRect(gfx.kColorBlack, 400, 50) --Make the charge bar
    gfx.pushContext(scoreBackgroundImage)
        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.drawText("Score: 0", 30, 30, 400, 240)
    gfx.popContext()
    scoreSprite = gfx.sprite.new(scoreBackgroundImage)
    scoreSprite:moveTo(200,-3)
    scoreSprite:add()
    scoreSprite:setZIndex(32760)

    scoreBackgroundWhiteImage = makeNewFilledRect(gfx.kColorWhite, 410, 60)
    scoreBackgroundSprite = gfx.sprite.new(scoreBackgroundWhiteImage)
    scoreBackgroundSprite:moveTo(200,-3)
    scoreBackgroundSprite:setZIndex(32759)
    scoreBackgroundSprite:add()

    randomizeBars(1, 450)
    randomizeBars(2, 675)

    gameBGM:play(0)

end

function updateGame() -- Main function

    -- HANDLE COLLISIONS
    local collisions = gfx.sprite.allOverlappingSprites()

    for i = 1, #collisions do
        local collisionPair = collisions[i]
        local sprite1 = collisionPair[1]
        local sprite2 = collisionPair[2]
        if (((sprite1 == playerSprite) and ((sprite2 == movingBarSpriteOneB) or (sprite2 == movingBarSpriteOneT) or (sprite2 == movingBarSpriteTwoB) or (sprite2 == movingBarSpriteTwoT)))) then
            runPlayerDamage = playerDamageTimer
            explodeSFX:play()
        else
            if (((sprite2 == playerSprite) and ((sprite1 == movingBarSpriteOneB) or (sprite1 == movingBarSpriteOneT) or (sprite1 == movingBarSpriteTwoB) or (sprite1 == movingBarSpriteTwoT)))) then
                runPlayerDamage = playerDamageTimer
                explodeSFX:play()
            end
        end

        if (((sprite1 == playerSprite) and (sprite2 == multiplierSprite)) or ((sprite1 == multiplierSprite) and (sprite2 == playerSprite))) then
            increaseMultiplier()
            multiplierSprite:moveTo(multiplierSprite.x, -40)
            currentMultiplierSprite:add()
        end
    end

    -- HANDLE CRANK
    local change, acceleratedChange = playdate.getCrankChange()

    currentCrankVel += acceleratedChange -- add the acceleratedChange to the charge, because the faster you turn the faster you get charge

    currentCrankVel = clamp(currentCrankVel, -1000, 680) -- make sure it doesn't go out of bounds

    chargeBarCover:moveTo(0,(1000 + currentCrankVel) / 7)

    crankPercentage = (math.abs(currentCrankVel - 680) / 1680) -- calculate a percentage of the crank guage between 0 and 1

    -- HANDLE PLAYER

    local thrustChange = (crankPercentage * 2) - 1
    playerVelY -= thrustChange

    playerSprite:moveTo(200, playerSprite.y + playerVelY)

    if (playerSprite.y < 0) then
        runPlayerDamage = playerDamageTimer
        explodeSFX:play()
    end
    if (playerSprite.y > 265) then
        runPlayerDamage = playerDamageTimer
        explodeSFX:play()
    end

    playerSprite:setRotation(1000 * ((1 / (math.exp((crankPercentage - 0.5) / 3) + 1)) - 0.5 ))

    -- MOVE BARS
    moveBars(barSpeed)

    -- HANDLE MULTIPLIER
    handleMultiplierSprite(barSpeed)

    -- HANDLE POINTS

    if (not pointTimerRunning) then
        pointTimer = playdate.timer.performAfterDelay(infinite_approach(1000, 0, 500, barSpeed - 2), pointTimerCallback)
        pointTimerRunning = true
        scoreBackgroundImage = makeNewFilledRect(gfx.kColorBlack, 400, 50)
        gfx.pushContext(scoreBackgroundImage)
            gfx.setImageDrawMode(gfx.kDrawModeNXOR)
            gfx.drawText("Score: " .. tostring(points), 30, 30, 400, 240)
        gfx.popContext()
        scoreSprite:setImage(scoreBackgroundImage)
    end

end

function pointTimerCallback()
    points += 1 * currentMultiplier
    pointTimerRunning = false
    barSpeed += 0.5
end

function applyDeathEffect()
    damageimage = gfx.getWorkingImage()
    damagesprite:setImage(damageimage:vcrPauseFilterImage())
    damagesprite:add()
    runPlayerDamage -= 1
    playerDeathCompleted = true
    deathQuoteString = deathQuoteStrings[ math.random( #deathQuoteStrings ) ]
end

function disposeAllGameObjects()

    damagesprite:remove()
    playerSprite:remove()
    scoreSprite:remove()
    chargeBarBackground:remove()
    chargeBarValue:remove()
    chargeBarCover:remove()
    multiplierSprite:remove()
    currentMultiplierSprite:remove()

    movingBarSpriteOneB:remove()
    movingBarSpriteOneT:remove()
    movingBarSpriteTwoB:remove()
    movingBarSpriteTwoT:remove()

    scoreBackgroundSprite:remove()

    chargeBarWhiteBackground:remove()

    multiplierInverseSprite:remove()

    crashBGM:stop(0)

end

-- Automatically runs once per frame
function game_update(reduceFlashingEffects)

    damagesprite:remove()

    if (runPlayerDamage > 0) then
        gameBGM:stop()
        crashBGM:play(0)

        if (pointTimer ~= nil) then
            pointTimer:remove()
        end
        if (reduceFlashingEffects and not hasAppliedVhsEffect) then
            applyDeathEffect()
            hasAppliedVhsEffect = true
        else
            if (not reduceFlashingEffects) then
                applyDeathEffect()
            else
                damagesprite:add()
                runPlayerDamage -= 1
            end
        end

    else
        if (playerDeathCompleted) then
            local drawTextOnThis = gfx.getWorkingImage()
            if (not reduceFlashingEffects) then
                drawTextOnThis = damageimage:vcrPauseFilterImage()
                gfx.pushContext(drawTextOnThis)
                    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
                    gfx.fillRoundRect(90,110,250,170,5)
                gfx.popContext()
            else
                drawTextOnThis = damagesprite:getImage()
                gfx.pushContext(drawTextOnThis)
                    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
                    gfx.fillRoundRect(90,110,250,170,5)
                gfx.popContext()
            end
            drawTextOnImage(drawTextOnThis, gfx.kDrawModeNXOR, deathQuoteString .. "\n\n*You scored: " .. tostring(points) .. "*", 100, 120)
            damagesprite:setImage(drawTextOnThis)
            damagesprite:add()

            if (not isTransitioning) then
                if (playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonB)) then

                    transitionSprite:moveTo(800, 120)
                    isTransitioning = true
                    transitionDirection = -40

                    return (points)
                end
            end

        else
            if (not isTransitioning) then
                updateGame()
            end
        end
    end
end
