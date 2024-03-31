# edX CS50 Introduction to Game Development: Flappy Bird

This is `Project 1` for [CS50's Introduction to Game Development](https://cs50.harvard.edu/games/2018/).

![flappy bird demo](./assets/flappy.gif)

The game is a clone of the popular mobile game Flappy Bird, and the goal is to take the provided [Love2D](https://love2d.org/) project and add several features to it:

- [x] More interesting procedural level generation
- [x] A Pause feature
- [x] An award system using medals for various scores

## Better Level Generation

The initial level generation relies on some hard-coded values to determine the gap between pipes and the height of the pipes themselves. This is fine for a simple game, but my first inclination was to make this value random. Truly random values between a mininum and maximum didn't feel quite right, so I ended up with a list of pre-defined values that would be randomly selected from.

```lua
-- the gap between pipes will be a random value
local GAP_HEIGHTS = { 80, 90, 100, 110, 120, 130 }
```

I'm bad a Flappy Bird, though. So to make this a little more fun for players like me, I decided to break the gap heights into three levels of difficulty and increase the difficulty by decreasing the gap height based on the user's current sore.
  
```lua
-- we'll dynamically generate the gap height based on the score to increase difficulty as the player progresses
LOW_SCORE_GAP_HEIGHTS = {110, 120, 130}
MEDIUM_SCORE_GAP_HEIGHTS = {90, 100, 110}
HIGH_SCORE_GAP_HEIGHTS = {70, 80, 90}
```

And then when generating a pair of pipes, we pass a dynamic gap height value to the constructor:

```lua
-- get a dynamic gap height
local gapHeight

if self.score < 5 then
    gapHeight = LOW_SCORE_GAP_HEIGHTS[math.random(#LOW_SCORE_GAP_HEIGHTS)]
elseif self.score < 10 then
    gapHeight = MEDIUM_SCORE_GAP_HEIGHTS[math.random(#MEDIUM_SCORE_GAP_HEIGHTS)]
else
    gapHeight = HIGH_SCORE_GAP_HEIGHTS[math.random(#HIGH_SCORE_GAP_HEIGHTS)]
end

-- modify the last Y coordinate we placed so pipe gaps aren't too far apart
-- no higher than 10 pixels below the top edge of the screen,
-- and no lower than a gap length (90 pixels) from the bottom
local y = math.max(-PIPE_HEIGHT + 10, 
    math.min(self.lastY + math.random(-20, 20), VIRTUAL_HEIGHT - gapHeight - PIPE_HEIGHT))
self.lastY = y

-- add a new pipe pair at the end of the screen at our new Y
table.insert(self.pipePairs, PipePair(y, gapHeight))
```

### Moving Pipes

In addition to variable gap height that shrinks with increasing scores, I also introduced a moving pipe mechanic that shifts the pipe pairs vertically at a speed that increases with the player's score.

These pipes are also more likely to appear as the player's score increases and are worth more points than regular pipes.

We also decrease the time between pipe spawns as the player's score increases to make the game more challenging.

```lua
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
```

Because they are procedurally generated and could create some difficult situations, there is also a point multiplier that increments with consecutive moving pipes to reward skilled players who are presented with a more difficult level.

A new sound effect was added to indicate a difference in points earned when passing a moving pipe.

```lua
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
```

#### Closing Pipes

In my first implementation of moving pipes, I was incorreclty setting the pipe's moving direction at the `Pip` level, which lead to some unexpected results where pipes would be opening/closing instead of moving vertically in unison.

It was a fun effect that added some additional challenge to the game, but requires some extra logic to make sure the pipes don't close too much and prevent the player from moving through the gap.

This is a feature that I might circle back to as a future update once the user's score gets to a certain level, but the effort required to make a level still be fun and playable with pipes that can close the gap is a bit more than I want to tackle right now for this project.

## Pausing the Game

There are a few considerations when pausing the game:

1. The background scrolling should stop
2. The music should stop
3. Gravity should stop
4. The player should not lose track of the level and where they are
5. (Optional) The player should have an indication that the game is paused and how to resume

My first and most naive attempt was to clone the `TitleScreenState.lua` file and create a new `PauseScreenState.lua` game state that renders out the paused text and then transition the player back to the countdown state after unpausing.

This worked, but was not ideal because the level would restart and the background would continue scrolling.

There had to be a better way.

### Pausing the Parallax Effect

First, I made a slight tweak to the `love.render()` method in the `main.lua` file to only activate the parallax effect if `scrolling` was set to `true`.

```lua
function love.update(dt)
    -- scroll our background and ground, looping back to 0 after a certain amount
    if scrolling then
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH
    end

    gStateMachine:update(dt)

    love.keyboard.keysPressed = {}
    love.mouse.buttonsPressed = {}
end
```

I think this might have been the original intention, but was left out in the final code distributed to us as part of this project.

### Pausing Play

Adding a simple `paused` variable to the `PlayState` class allowed me to pause the game and stop gravity from affecting the player by wrapping all of the existing logic for updating the player in an `if not self.paused then` block.

Then it was just a matter of checking for the pause button press and stopping the relevant game effects in the `PlayState`'s `update()` method:

```lua
function PlayState:update(dt)
  -- toggle paused state when enter/return is pressed
  if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
    -- toggle paused
    self.paused = not self.paused
    scrolling = not scrolling

    if sounds['music']:isPlaying() then
        sounds['music']:pause()
    else
        sounds['music']:play()
    end
  end

  if not self.paused then
    -- existing game logic
  end
end
```

## Medals for High Scores

The final goal of this project was to add a simple achievement/medal system that would reward players for various scores.

I decided to go with a system based on multiples of `7`:

- `7` points: **Silver Medal**
- `14` points: **Gold Medal**
- `21` points: **Platinum Medal**

The medals are displayed in the `ScoreState` screen and are simple pixel art images generated in Aseprite using the provided `bird.png` as a base.

Given more time to play around with it, I would probably create more achievements for things like:

- colliding with a moving pipe that's hidden off screen
- colliding with the side of a pipe instead of the top/bottom in the gap
- passing a certain number of moving pipes in a row
- passing a certain number of moving pipes total