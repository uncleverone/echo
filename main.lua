inspect = require('lib.inspect')
_       = require('lib.underscore')
class   = require('lib.hump.class')

HC       = require('lib.HardonCollider')
collider = HC(100,on_collide)

local Echo = require('echo')

echoes = {}

function love.load()
    -- level_data = love.filesystem.load('lvls/001.lua')


    -- print('Without inspect: ')
    -- print( level_data() )
    -- print('With inspect:')
    -- print(inspect(level_data()))


    -- local test_box = {screen_w / 5, screen_h / 5, 3*screen_w / 5, 3*screen_h / 5}

    local screen_w, screen_h = love.graphics.getDimensions()
    local test_box = collider:addRectangle(screen_w / 5, screen_h / 5, 3*screen_w / 5, 3*screen_h / 5)
    collider:setPassive(test_box)
    test_box.color = {255,255,255}

    -- table.insert(boxes, test_box)

end

function love.draw()
    local screen_w, screen_h = love.graphics.getDimensions()

    -- draw only visible shapes
    -- SKIP ECHOS FOR NOW (hence no circle)
    for shape in pairs(collider:shapesInRange(0,0, screen_w,screen_h)) do
        if shape._type == 'polygon' then
            local r, g, b, a = love.graphics.getColor()
                love.graphics.setColor(unpack(shape.color))
                shape:draw()
            love.graphics.setColor(r,g,b,a)
        end
    end

    for i,echo in ipairs(echoes) do
        echo:draw()
    end
end

function love.update(dt)
    for i,echo in ipairs(echoes) do
        echo:update(dt)
        if not echo.collider_shape then
            table.remove(echoes,i)
        end
    end
end

function love.keypressed(key, isrepeat)
    if key == 'escape' then love.event.quit() end
end

function love.mousepressed(x, y, button)
    -- x,y,t
    local echo = Echo(collider,x,y)
    table.insert(echoes, echo)
end


function on_collide(dt, shape, other_shape)

end

function on_stop_colliding(dt, shape_one, shape_two)

end

