inspect = require('lib.inspect')
_       = require('lib.underscore')
class   = require('lib.hump.class')



local Echo = require('echo')


function love.load()

    HC       = require('lib.HardonCollider')
    collider = HC(100,on_collide, on_stop_colliding)

    echoes = {}
    -- level_data = love.filesystem.load('lvls/001.lua')


    -- print('Without inspect: ')
    -- print( level_data() )
    -- print('With inspect:')
    -- print(inspect(level_data()))


    -- local test_box = {screen_w / 5, screen_h / 5, 3*screen_w / 5, 3*screen_h / 5}

    local screen_w, screen_h = love.graphics.getDimensions()

    -- local pts = {     screen_w / 5, screen_h / 5, 
    --                 4*screen_w / 5, screen_h / 5, 
    --                 4*screen_w / 5, 4*screen_h / 5, 
    --                 screen_w / 5, 4*screen_h / 5, 
    --                 screen_w / 5, screen_h / 5 }

    -- local test_box = collider:addPolyline(unpack(pts))
    line1 = collider:addPolyline(screen_w / 5, screen_h / 5, 4*screen_w / 5, screen_h / 5)
    line2 = collider:addPolyline(4*screen_w / 5, screen_h / 5, 4*screen_w / 5, 4*screen_h / 5)
    line3 = collider:addPolyline(4*screen_w / 5, 4*screen_h / 5, screen_w / 5, 4*screen_h / 5)
    line4 = collider:addPolyline(screen_w / 5, 4*screen_h / 5, screen_w / 5, screen_h / 5)

    collider:addToGroup('box',line1, line2, line3, line4)

    line1.is_colliding = false
    line2.is_colliding = false
    line3.is_colliding = false
    line4.is_colliding = false

    -- table.insert(boxes, test_box)

end

function love.draw()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(50,50,50)
        collider._hash:draw()
    love.graphics.setColor(r,g,b,a)

    local screen_w, screen_h = love.graphics.getDimensions()

    -- draw only visible shapes
    -- SKIP ECHOS FOR NOW (hence no circle)
    for shape in pairs(collider:shapesInRange(0,0, screen_w,screen_h)) do
        if shape._type == 'polyline' then
            local r, g, b, a = love.graphics.getColor()
                if shape.is_colliding then
                    love.graphics.setColor(255,0,0)
                end
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

    collider:update(dt)
end

function love.keypressed(key, isrepeat)
    if key == 'escape' then love.event.quit() end
end

function love.mousepressed(x, y, button)
    -- x,y,t
    local echo = Echo(collider,x,y,10)
    table.insert(echoes, echo)
end


function on_collide(dt, shape, other_shape, dx, dy)
    print('shape: '..shape._type)
    print('other_shape: '..other_shape._type)
    other_shape.is_colliding = true
end

function on_stop_colliding(dt, shape, other_shape)
    other_shape.is_colliding = false
end

