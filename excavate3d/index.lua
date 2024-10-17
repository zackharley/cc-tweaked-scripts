local tArgs = { ... }

local function getDimensions()
  if #tArgs == 3 then
    local length = tonumber(tArgs[1])
    local width = tonumber(tArgs[2])
    local depth = tonumber(tArgs[3])
    if length and width and depth and length > 0 and width > 0 and depth > 0 then
      return length, width, depth
    else
      print("Error: All dimensions must be positive integers.")
      return nil, nil, nil
    end
  else
    print("Enter length:")
    local length = tonumber(read())
    print("Enter width:")
    local width = tonumber(read())
    print("Enter depth:")
    local depth = tonumber(read())
    if length and width and depth and length > 0 and width > 0 and depth > 0 then
      return length, width, depth
    else
      print("Error: All dimensions must be positive integers.")
      return nil, nil, nil
    end
  end
end

local length, width, depth = getDimensions()

if not length or not width or not depth then
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

local function digLayer()
  for w = 1, width do
    for l = 1, length - 1 do
      if not checkFuel() then return false end
      turtle.dig()
      if not moveForward() then return false end
    end
    if w < width then
      if w % 2 == 1 then
        turnRight()
        if not checkFuel() then return false end
        turtle.dig()
        if not moveForward() then return false end
        turnRight()
      else
        turnLeft()
        if not checkFuel() then return false end
        turtle.dig()
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
      if not moveDown() then return end
    end
  end
  -- Return to the original height
  for d = 1, depth - 1 do
    if not moveUp() then return end
  end
  print("Excavation complete.")
end

excavate()
