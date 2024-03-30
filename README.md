# edX CS50 Introduction to Game Development: Flappy Bird

This is `Project 1` for [CS50's Introduction to Game Development](https://cs50.harvard.edu/games/2018/).

The game is a clone of the popular mobile game Flappy Bird, and the goal is to take the provided [Love2D](https://love2d.org/) project and add several features to it:

- [x] A Pause feature
- [ ] An award system using medals for various scores
- [ ] More interesting procedural level generation

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