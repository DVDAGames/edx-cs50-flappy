--[[
    PipePair Class

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Used to represent a pair of pipes that stick together as they scroll, providing an opening
    for the player to jump through in order to score a point.
]]

PipePair = Class{}

-- size of the gap between pipes


function PipePair:init(y, gapHeight, isMoving, pipeMovingSpeed)
    -- flag to hold whether this pair has been scored (jumped through)
    self.scored = false

    -- initialize pipes past the end of the screen
    self.x = VIRTUAL_WIDTH + 32

    -- y value is for the topmost pipe; gap is a vertical shift of the second lower pipe
    self.y = y

    -- set the gap between pipes
    self.gapHeight = gapHeight

    self.isMoving = isMoving
    self.pipeMovingSpeed = pipeMovingSpeed
    
    if self.isMoving then
        self.pipeMovingDirection = math.random(2) == 1 and 1 or -1
    else
        self.pipeMovingDirection = 0
    end

    -- instantiate two pipes that belong to this pair
    self.pipes = {
        ['upper'] = Pipe('top', self.y, self.isMoving, self.pipeMovingSpeed, self.pipeMovingDirection),
        ['lower'] = Pipe('bottom', self.y + PIPE_HEIGHT + self.gapHeight, self.isMoving, self.pipeMovingSpeed, self.pipeMovingDirection)
    }

    -- whether this pipe pair is ready to be removed from the scene
    self.remove = false
end

function PipePair:update(dt)
    self.pipes['lower']:update(dt)
    self.pipes['upper']:update(dt)

    -- remove the pipe from the scene if it's beyond the left edge of the screen,
    -- else move it from right to left
    if self.x > -PIPE_WIDTH then
        self.x = self.x - PIPE_SPEED * dt
        self.pipes['lower'].x = self.x
        self.pipes['upper'].x = self.x
    else
        self.remove = true
    end
end

function PipePair:render()
    for l, pipe in pairs(self.pipes) do
        pipe:render()
    end
end