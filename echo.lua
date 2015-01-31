local Echo = class({})

function Echo:init(collider, x, y, velocity, radius)
	if x == nil or y == nil then
		error('Invalid x and/or y for Echo(x,y)')
	end

	self.x = x
	self.y = y

	self.velocity = velocity or 100.0
	self.radius   = radius   or    .01 -- nonzero so a circle:draw() doesn't bork

	self.collider_shape = collider:addCircle(self.x, self.y, self.radius)
	collider:addToGroup('echoes', self.collider_shape)

	self.color = {100,100,255}
end

function Echo:update(dt)
	local screen_w, screen_h = love.graphics.getDimensions()
	local MAX_RADIUS         = math.sqrt(screen_w*screen_w + screen_h*screen_h)

	self.radius = self.radius + self.velocity * dt
	self.collider_shape._radius = self.radius

	if self.radius > MAX_RADIUS then
		print('Removing shape from collider:',inspect(self.collider_shape._center))
		collider:remove(self.collider_shape)
		self.collider_shape = nil
	end
end

function Echo:draw()
	local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(unpack(self.color))
        self.collider_shape:draw()
    love.graphics.setColor(r,g,b,a)
end

function Echo:on_collision(...)

end

function Echo:on_stop_collision(...)

end

return Echo