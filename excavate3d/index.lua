-- Function to prompt for input and convert it to a number
local function promptDimension(prompt)
  print(prompt)
  return tonumber(read())
end

-- Instruction to the user to ensure proper turtle placement
print(
  "Please ensure that the turtle is positioned at the top-left corner of the 3D rectangle, at the highest level, and facing down the length of the mining area.")

-- Prompt the user for the mining area dimensions
local width = promptDimension("Enter the width of the mining area:")
local length = promptDimension("Enter the length of the mining area:")
local height = promptDimension("Enter the height (depth) of the mining area:")

-- Starting position for returning
local startX, startY, startZ = 0, height - 1, 0
local direction = 1 -- 1: forward, -1: backward (for zig-zag movement)

-- Track position
local x, y, z = 0, height - 1, 0

-- Function to refuel the turtle if necessary
local function refuel()
  for slot = 1, 16 do
    if turtle.getFuelLevel() < 10 and turtle.getItemCount(slot) > 0 then
      turtle.select(slot)
      turtle.refuel()
    end
  end
end

-- Function to return to start position and drop off non-fuel items
local function returnToStartAndDump()
  -- Return to starting height
  while y < height - 1 do
    turtle.up()
    y = y + 1
  end

  -- Return to starting Z
  while z > 0 do
    turtle.forward()
    z = z - 1
  end

  -- Return to starting X
  while x > 0 do
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    x = x - 1
  end

  -- Drop off non-fuel items
  for slot = 1, 16 do
    turtle.select(slot)
    if not turtle.refuel(0) then -- Skip fuel items
      turtle.dropDown()
    end
  end
end

-- Function to move the turtle in a zig-zag pattern and mine a single layer
local function mineLayer()
  for i = 1, length do
    for j = 1, width - 1 do
      turtle.dig()
      turtle.forward()
      refuel()
      z = z + direction
    end
    -- Move to next row if not at the last row of this layer
    if i < length then
      if direction == 1 then
        turtle.turnRight()
        turtle.dig()
        turtle.forward()
        turtle.turnRight()
      else
        turtle.turnLeft()
        turtle.dig()
        turtle.forward()
        turtle.turnLeft()
      end
      refuel()
      x = x + 1
    end
    -- Reverse the direction for the next row
    direction = -direction
  end
end

-- Main function to mine all layers from top to bottom
local function mineArea()
  for h = 1, height do
    -- Mine the current layer
    mineLayer()

    -- If we're not at the bottom layer, move down
    if h < height then
      turtle.digDown()
      turtle.down()
      refuel()
      y = y - 1

      -- Reset the x, z coordinates for the new layer
      -- Make sure the turtle is in the same position at the start of each new layer
      if direction == -1 then
        -- If the last row was done backward, we need to correct the direction and move back to the start of the next layer
        turtle.turnRight()
        turtle.turnRight()
        direction = 1
      end
      x, z = 0, 0
    end

    -- Check if inventory is full and return to dump if necessary
    local full = true
    for slot = 1, 16 do
      if turtle.getItemCount(slot) == 0 then
        full = false
        break
      end
    end
    -- Return to start if inventory is full
    if full then
      returnToStartAndDump()
    end
  end
  -- After mining, return to the starting point
  returnToStartAndDump()
end

-- Start mining the area
mineArea()
