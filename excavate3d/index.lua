local tArgs = { ... }

local function getDimensionsAndMode()
  if #tArgs == 4 then
    local length = tonumber(tArgs[1])
    local width = tonumber(tArgs[2])
    local depth = tonumber(tArgs[3])
    local mode = tArgs[4]:lower()
    if length and width and depth and length > 0 and width > 0 and depth > 0 and (mode == "drop" or mode == "store") then
      return length, width, depth, mode
    else
      print("Error: All dimensions must be positive integers, and mode must be 'drop' or 'store'.")
      return nil, nil, nil, nil
    end
  else
    print("Enter length:")
    local length = tonumber(read())
    print("Enter width:")
    local width = tonumber(read())
    print("Enter depth:")
    local depth = tonumber(read())
    print("Enter mode ('drop' or 'store'):")
    local mode = read():lower()
    if length and width and depth and length > 0 and width > 0 and depth > 0 and (mode == "drop" or mode == "store") then
      return length, width, depth, mode
    else
      print("Error: All dimensions must be positive integers, and mode must be 'drop' or 'store'.")
      return nil, nil, nil, nil
    end
  end
end

local length, width, depth, mode = getDimensionsAndMode()

if not length or not width or not depth or not mode then
  return
end

local currentX, currentY, currentZ = 0, 0, 0
local currentDirection = 0 -- 0: east, 1: south, 2: west, 3: north

local function checkFuel()
  if turtle.getFuelLevel() == 0 then
    print("Error: Out of fuel.")
    return false
  end
  return true
end

local function withinBounds(x, y, z)
  return x >= 0 and x < length and
      y >= -depth and y <= 0 and
      z >= 0 and z < width
end

local function moveForward()
  local newX, newZ = currentX, currentZ
  if turtle.forward() then
    if currentDirection == 0 then
      newX = currentX + 1
    elseif currentDirection == 1 then
      newZ = currentZ + 1
    elseif currentDirection == 2 then
      newX = currentX - 1
    elseif currentDirection == 3 then
      newZ = currentZ - 1
    end
    if withinBounds(newX, currentY, newZ) then
      currentX, currentZ = newX, newZ
      return true
    else
      print("Error: Out of bounds.")
      return false
    end
  else
    print("Error: Unable to move forward.")
    return false
  end
end

local function moveDown()
  local newY = currentY - 1
  if withinBounds(currentX, newY, currentZ) and turtle.down() then
    currentY = newY
    return true
  else
    print("Error: Unable to move down or out of bounds.")
    return false
  end
end

local function moveUp()
  local newY = currentY + 1
  if withinBounds(currentX, newY, currentZ) and turtle.up() then
    currentY = newY
    return true
  else
    print("Error: Unable to move up or out of bounds.")
    return false
  end
end

local function turnRight()
  turtle.turnRight()
  currentDirection = (currentDirection + 1) % 4
end

local function turnLeft()
  turtle.turnLeft()
  currentDirection = (currentDirection - 1) % 4
  if currentDirection < 0 then
    currentDirection = currentDirection + 4
  end
end

local function reverseDirection()
  turnLeft()
  turnLeft()
end

local function handleFullInventory()
  if mode == "drop" then
    for slot = 1, 16 do
      if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        turtle.drop()
      end
    end
  elseif mode == "store" then
    -- Move to the starting position to store items
    reverseDirection()
    for i = 1, currentX do
      turtle.back()
    end
    for i = 1, currentZ do
      turnLeft()
      turtle.forward()
      turnRight()
    end
    -- Drop items in the chest behind the starting position
    turtle.turnRight()
    for slot = 1, 16 do
      if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        turtle.drop()
      end
    end
    turtle.turnLeft()
    -- Return to the previous position
    for i = 1, currentZ do
      turnLeft()
      turtle.back()
      turnRight()
    end
    for i = 1, currentX do
      turtle.forward()
    end
    reverseDirection()
  end
end

local function digLayer()
  for w = 1, width do
    for l = 1, length - 1 do
      if not checkFuel() then return false end
      turtle.dig()
      if turtle.getItemCount(16) > 0 then
        handleFullInventory()
      end
      if not moveForward() then return false end
    end
    if w < width then
      if w % 2 == 1 then
        turnRight()
        if not checkFuel() then return false end
        turtle.dig()
        if turtle.getItemCount(16) > 0 then
          handleFullInventory()
        end
        if not moveForward() then return false end
        turnRight()
      else
        turnLeft()
        if not checkFuel() then return false end
        turtle.dig()
        if turtle.getItemCount(16) > 0 then
          handleFullInventory()
        end
        if not moveForward() then return false end
        turnLeft()
      end
    end
  end
  return true
end

local function excavate()
  for d = 1, depth do
    if not digLayer() then return end
    if d < depth then
      if not checkFuel() then return end
      turtle.digDown()
      if turtle.getItemCount(16) > 0 then
        handleFullInventory()
      end
      if not moveDown() then return end
      reverseDirection() -- Turn around to continue clearing in the same rectangular prism
    end
  end
  -- Return to the original height
  for d = 1, depth - 1 do
    if not moveUp() then return end
  end
  print("Excavation complete.")
end

excavate()
