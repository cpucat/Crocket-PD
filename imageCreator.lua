import "CoreLibs/graphics"
local gfx <const> = playdate.graphics

function makeNewFilledRoundRect(color, x, y, w) -- Returns a new gfx image with a filledRoundRect filling it
    local newRect = gfx.image.new(x, y)
    gfx.pushContext(newRect)
        gfx.setColor(color)
        gfx.fillRoundRect(0,0,x,y,w)
    gfx.popContext()
    return newRect
end

function makeNewFilledRect(color, x, y) -- Returns a new gfx image with a filledRect filling it
    local newRect = gfx.image.new(x, y)
    gfx.pushContext(newRect)
        gfx.setColor(color)
        gfx.fillRect(0,0,x,y,w)
    gfx.popContext()
    return newRect
end

function makeNewCircle(color, x) -- Returns a new gfx image with a filledRect filling it
    local newRect = gfx.image.new(x, x)
    gfx.pushContext(newRect)
        gfx.setColor(color)
        gfx.drawCircleInRect(0, 0, x, x)
    gfx.popContext()
    return newRect
end

function drawTextOnImage(image, drawMode, text, x, y)
    local width, height = image:getSize()

    gfx.pushContext(image)
        gfx.setImageDrawMode(drawMode)
        gfx.drawText(text, x, y, width - x, height - y, playdate.graphics.kWrapCharacter)
    gfx.popContext()
    return image
end

function drawPixelOnImage(image, color, x, y)
    gfx.pushContext(image)
        gfx.setColor(color)
        gfx.drawPixel(x, y)
    gfx.popContext()
    return image
end
