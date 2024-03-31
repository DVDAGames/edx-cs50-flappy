--[[
    PlayState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The PlayState class is the bulk of the game, where the player actually controls the bird and
    avoids pipes. When the player collides with a pipe, we should go to the GameOver state, where
    we then go back to the main menu.
]]

PlayState = Class{__includes = BaseState}

PIPE_SPEED = 60
PIPE_WIDTH = 70
PIPE_HEIGHT = 288

BIRD_WIDTH = 38
BIRD_HEIGHT = 24

-- we'll dynamically generate the gap height based on the score to increase difficulty as the player progresses
LOW_SCORE_GAP_HEIGHTS = {110, 120, 130}
MEDIUM_SCORE_GAP_HEIGHTS = {90, 100, 110}
HIGH_SCORE_GAP_HEIGHTS = {70, 80, 90}

PIPE_MOVING_SPEED = {5, 10, 15, 20}

function PlayState:init()
    self.bird = Bird()
    self.pipePairs = {}
    self.timer = 0
    self.score = 0

    -- initialize our last recorded Y value for a gap placement to base other gaps off of
    self.lastY = -PIPE_HEIGHT + math.random(80) + 20

    -- we'll implement a score multiplier if the player navigates multiple moving pipes in a row
    self.scoreMultiplier = 1

    self.spawnTimer = math.random(1.5, 3.5)

    self.paused = false
end

function PlayState:update(dt)
    -- toggle paused state when enter/return is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        -- toggle paused
        self.paused = not self.paused
        scrolling = not scrolling
        
        if sounds['music']:isPlaying() then
            sounds['music']:pause()
            sounds['pause']:play()
        else
            sounds['unpause']:play()
            sounds['music']:play()
        end
    end

    if not self.paused then
        -- update timer for pipe spawning
        self.timer = self.timer + dt

        -- spawn a new pipe pair
        if self.timer > self.spawnTimer then
            local gapHeight = 90
            local isMoving = false
            local pipeMovingSpeed = 0

            if self.score < 5 then
                self.spawnTimer = math.random(1.5, 3.5)
                gapHeight = LOW_SCORE_GAP_HEIGHTS[math.random(#LOW_SCORE_GAP_HEIGHTS)]
                isMoving = math.random(10) < 2
                pipeMovingSpeed = PIPE_MOVING_SPEED[1]
            elseif self.score < 10 then
                self.spawnTimer = math.random(1.5, 3)
                gapHeight = MEDIUM_SCORE_GAP_HEIGHTS[math.random(#MEDIUM_SCORE_GAP_HEIGHTS)]
                isMoving = math.random(10) < 4
                pipeMovingSpeed = PIPE_MOVING_SPEED[2]
            else
                self.spawnTimer = math.random(1.5, 2.5)
                gapHeight = HIGH_SCORE_GAP_HEIGHTS[math.random(#HIGH_SCORE_GAP_HEIGHTS)]
                isMoving = math.random(10) < 7
                pipeMovingSpeed = PIPE_MOVING_SPEED[3]

                if self.score > 20 then
                    self.spawnTimer = math.random(1.5, 2)
                    pipeMovingSpeed = PIPE_MOVING_SPEED[4]
                end
            end

            -- modify the last Y coordinate we placed so pipe gaps aren't too far apart
            -- no higher than 10 pixels below the top edge of the screen,
            -- and no lower than a gap length (90 pixels) from the bottom
            local y = math.max(-PIPE_HEIGHT + 10, 
                math.min(self.lastY + math.random(-20, 20), VIRTUAL_HEIGHT - gapHeight - PIPE_HEIGHT))
            
            self.lastY = y

            -- add a new pipe pair at the end of the screen at our new Y
            table.insert(self.pipePairs, PipePair(y, gapHeight, isMoving, pipeMovingSpeed))

            -- reset timer
            self.timer = 0
        end

        -- for every pair of pipes
        for k, pair in pairs(self.pipePairs) do
            -- score a point if the pipe has gone past the bird to the left all the way
            -- be sure to ignore it if it's already been scored
            if not pair.scored then
                if pair.x + PIPE_WIDTH < self.bird.x then
                    sounds['score']:play()

                    -- handle point multipliers for moving pipes
                    if pair.isMoving then
                        self.scoreMultiplier = self.scoreMultiplier + 1
                        self.score = self.score + 1 * self.scoreMultiplier

                        sounds['multiplier']:play()
                    else
                        self.scoreMultiplier = 1
                        self.score = self.score + 1
                    end

                    pair.scored = true
                end
            end

            -- update position of pair
            pair:update(dt)
        end

        -- we need this second loop, rather than deleting in the previous loop, because
        -- modifying the table in-place without explicit keys will result in skipping the
        -- next pipe, since all implicit keys (numerical indices) are automatically shifted
        -- down after a table removal
        for k, pair in pairs(self.pipePairs) do
            if pair.remove then
                table.remove(self.pipePairs, k)
            end
        end

        -- simple collision between bird and all pipes in pairs
        for k, pair in pairs(self.pipePairs) do
            for l, pipe in pairs(pair.pipes) do
                if self.bird:collides(pipe) then
                    sounds['explosion']:play()
                    sounds['hurt']:play()

                    gStateMachine:change('score', {
                        score = self.score
                    })
                end
            end
        end

        -- update bird based on gravity and input
        self.bird:update(dt)

        -- reset if we get to the ground
        if self.bird.y > VIRTUAL_HEIGHT - 15 then
            sounds['explosion']:play()
            sounds['hurt']:play()

            gStateMachine:change('score', {
                score = self.score
            })
        end
    end
end

function PlayState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    self.bird:render()

    if self.paused then
        love.graphics.setFont(mediumFont)
        love.graphics.printf('PAUSED', 0, VIRTUAL_HEIGHT / 2 - 64, VIRTUAL_WIDTH, 'center')

        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to Resume', 0, VIRTUAL_HEIGHT / 2 + 32, VIRTUAL_WIDTH, 'center')
    else
        love.graphics.setFont(flappyFont)
        love.graphics.print('Score: ' .. tostring(self.score), 8, 8)

        love.graphics.setFont(smallFont)
        love.graphics.print('Press Enter to Pause', 8, 40)
    end
end

--[[
    Called when this state is transitioned to from another state.
]]
function PlayState:enter()
    -- if we're coming from death, restart scrolling
    scrolling = true
end

--[[
    Called when this state changes to another state.
]]
function PlayState:exit()
    -- stop scrolling for the death/score screen
    scrolling = false
end