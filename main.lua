inspect = require('lib.inspect')
_       = require('lib.underscore')


HC       = require('lib.HardonCollider')
collider = HC(100,on_collide)


function love.load()
    level_data = love.filesystem.load('lvls/001.lua')


    -- print('Without inspect: ')
    -- print( level_data() )
    -- print('With inspect:')
    -- print(inspect(level_data()))


    -- local test_box = {screen_w / 5, screen_h / 5, 3*screen_w / 5, 3*screen_h / 5}

    local screen_w, screen_h = love.graphics.getDimensions()
    local test_box = collider:addRectangle(screen_w / 5, screen_h / 5, 3*screen_w / 5, 3*screen_h / 5)
    test_box.color = {255,255,255}

    -- table.insert(boxes, test_box)

end

function love.draw()
    local screen_w, screen_h = love.graphics.getDimensions()

    -- draw only visible shapes
    for shape in pairs(collider:shapesInRange(0,0, screen_w,screen_h)) do
        local r, g, b, a = love.graphics.getColor()
            love.graphics.setColor(unpack(shape.color))
            shape:draw()
        love.graphics.setColor(r,g,b,a)
    end
end

function love.update(dt)
    local screen_w, screen_h = love.graphics.getDimensions()
    local MAX_RADIUS = math.sqrt(screen_w*screen_w + screen_h*screen_h)

    for shape in pairs(collider:shapesInRange(0,0, screen_w,screen_h)) do
        if shape._type == 'circle' then
            shape._radius = shape._radius + 100*dt
            if shape._radius > MAX_RADIUS then
                print('Removing shape:',inspect(shape._center))
                collider:remove(shape)
            end
        end
    end
end

function love.keypressed(key, isrepeat)
    if key == 'escape' then love.event.quit() end
end

function love.mousepressed(x, y, button)
    -- x,y,t
    local p = collider:addCircle(x,y,0.01)
    p.color = {100,100,255}
end


function on_collide(dt, shape, other_shape)

end


