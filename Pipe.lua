--[[
    Pipe Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Pipe class represents the pipes that randomly spawn in our game, which act as our primary obstacles.
    The pipes can stick out a random distance from the top or bottom of the screen. When the player collides
    with one of them, it's game over. Rather than our bird actually moving through the screen horizontally,
    the pipes themselves scroll through the game to give the illusion of player movement.
]]

Pipe = Class{}

-- since we only want the image loaded once, not per instantation, define it externally
local PIPE_IMAGE = love.graphics.newImage('pipe.png')

function Pipe:init(orientation, y, isMoving, pipeMovingSpeed)
    self.x = VIRTUAL_WIDTH + 64
    self.y = y

    self.width = PIPE_WIDTH
    self.height = PIPE_HEIGHT

    self.orientation = orientation

    self.isMoving = isMoving
    self.pipeMovingSpeed = pipeMovingSpeed

    if self.isMoving then
        self.movingDirection = math.random(2) == 1 and 1 or -1
    else
        self.movingDirection = 0
    end

    self.timer = 0
end

function Pipe:update(dt)
    if self.isMoving then
        self.timer = self.timer + dt

        if self.orientation == 'top' then
            self.y = self.y - self.movingDirection * self.pipeMovingSpeed * dt
        else
            self.y = self.y + self.movingDirection * self.pipeMovingSpeed * dt
        end

        if self.timer > 5 then
            self.movingDirection = -self.movingDirection
            self.timer = 0
        end
    end
end

function Pipe:render()
    love.graphics.draw(PIPE_IMAGE, self.x, 

        -- shift pipe rendering down by its height if flipped vertically
        (self.orientation == 'top' and self.y + PIPE_HEIGHT or self.y), 

        -- scaling by -1 on a given axis flips (mirrors) the image on that axis
        0, 1, self.orientation == 'top' and -1 or 1)
end