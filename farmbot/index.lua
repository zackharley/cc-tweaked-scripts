-- Configuration
local fuelSlot = 1      -- Slot reserved for charcoal
local cropSlotStart = 2 -- Crops and seeds start in slot 2

local cropMaxGrowth = {
  ["minecraft:wheat"] = 7,
  ["minecraft:carrots"] = 7,
  ["minecraft:potatoes"] = 7,
  ["minecraft:beetroots"] = 3,
  ["farmersdelight:onions"] = 7,
  ["farmersdelight:tomatoes"] = 3
}

-- Asserted movement functions to handle failures
local function safeForward(times)
  for i = 1, (times or 1) do
    assert(turtle.forward())
  end
end

local function safeBack(times)
  for i = 1, (times or 1) do
    assert(turtle.back(), "Turtle failed to move backward")
  end
end

local function safeUp(times)
  for i = 1, (times or 1) do
    assert(turtle.up(), "Turtle failed to move up")
  end
end

local function safeDown(times)
  for i = 1, (times or 1) do
    assert(turtle.down(), "Turtle failed to move down")
  end
end

local function safeTurnLeft()
  assert(turtle.turnLeft(), "Turtle failed to turn left")
end

local function safeTurnRight()
  assert(turtle.turnRight(), "Turtle failed to turn right")
end

-- Generalized crop harvesting and replanting function for 11x5 area
local function harvestAndReplant()
  -- Start at (0, 3), move to (1, 1) to start harvesting
  safeForward()        -- Move to (1, 3)
  safeTurnLeft()       -- Face (1, 2)
  safeForward()        -- Move to (1, 2)
  safeForward()        -- Move to (1, 1)
  safeTurnRight()      -- Face (1, 1)

  for row = 1, 5 do    -- Loop through each row (1 to 5)
    for col = 1, 11 do -- Loop through each column (1 to 11)
      local success, data = turtle.inspectDown()

      -- Check if the block is a crop and has an "age" property
      if success and data.state and data.state.age then
        local maxGrowth = cropMaxGrowth[data.name]

        if not maxGrowth then
          error("Invalid crop detected: " .. data.name)
        end

        -- Check if the crop is fully grown
        if data.state.age == maxGrowth then
          turtle.digDown()   -- Harvest the fully grown crop
          turtle.placeDown() -- Replant the crop
        end
      end

      if col < 11 then
        safeForward() -- Move to the next column if not at the end of the row
      end
    end

    -- At the end of the row, prepare to move to the next row
    if row < 5 then -- If it's not the last row, move to the next row
      if row % 2 == 1 then
        -- Odd rows (1, 3, 5): turn right at the end of the row
        safeTurnRight()
        safeForward()
        safeTurnRight()
      else
        -- Even rows (2, 4): turn left at the end of the row
        safeTurnLeft()
        safeForward()
        safeTurnLeft()
      end
    end
  end

  -- Return to starting position after finishing the grid
  if (5 % 2 == 1) then -- If ending on an odd row, turn around
    safeTurnRight()
    safeTurnRight()
  end

  -- Return to central point
  safeTurnLeft() -- Face the Turtle back toward the central corridor
  safeForward()  -- Move to (1, 3)
  safeForward()  -- Move to (0, 3) (starting point)
end

-- Function to refuel the turtle
local function refuelTurtle()
  if turtle.getFuelLevel() < 100 then
    turtle.select(fuelSlot)

    -- Check if the fuel slot is empty
    if turtle.getItemCount(fuelSlot) == 0 then
      if turtle.suck() then -- Pull charcoal from the chest
        print("Charcoal pulled from chest.")
      else
        print("No charcoal available!")
      end
    else
      print("Fuel slot already contains charcoal.")
    end

    -- Refuel if there's charcoal in the slot
    if turtle.refuel() then
      print("Turtle refueled! Current fuel level: " .. turtle.getFuelLevel())
    else
      print("Failed to refuel. Check if fuel is available.")
    end
  end
end


-- Function to deposit harvested crops
local function depositCrops()
  for i = cropSlotStart, 16 do
    turtle.select(i)
    turtle.drop() -- Drop items in the homebase chest
  end
end

-- Function to navigate to a specific quadrant from the starting position
local function moveToQuadrant(quadrant)
  if quadrant == 1 then
    safeForward()
    safeTurnLeft()
    safeForward(6)
    safeTurnRight()
    safeForward()
  elseif quadrant == 2 then
    -- Movement logic to quadrant 2
    -- Move to the starting position of quadrant 2
  elseif quadrant == 3 then
    -- Movement logic to quadrant 3
    -- Move to the starting position of quadrant 3
  elseif quadrant == 4 then
    -- Movement logic to quadrant 4
    -- Move to the starting position of quadrant 4
  end
end

-- Function to return to the central station
local function returnToCenter()
  -- Logic to return the turtle to the central station
end

-- Main function to handle the process for all quadrants
local function harvestAllQuadrants()
  refuelTurtle()             -- Refuel the turtle before starting
  for quadrant = 1, 1 do
    moveToQuadrant(quadrant) -- Go to the respective quadrant
    harvestAndReplant()      -- Harvest and replant crops
    returnToCenter()         -- Go back to the central station
    -- refuelTurtle()           -- Refuel if needed
    -- depositCrops()           -- Drop off harvested crops
  end
end

-- Infinite loop to continuously harvest
-- while true do
harvestAllQuadrants() -- Harvest crops in all four quadrants
-- sleep(600)            -- Wait for crops to grow (adjust the timing as needed)
-- end
