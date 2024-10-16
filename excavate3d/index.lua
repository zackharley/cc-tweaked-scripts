local tArgs = { ... }

local function getDimensions()
  if #tArgs == 3 then
    return tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3])
  else
    print("Enter length:")
    local length = tonumber(read())
    print("Enter width:")
    local width = tonumber(read())
    print("Enter depth:")
    local depth = tonumber(read())
    return length, width, depth
  end
end

local length, width, depth = getDimensions()

if not length or not width or not depth then
  print("Error: All dimensions must be valid numbers.")
  return
end

local startX, startY, startZ = gps.locate()
if not startX or not startY or not startZ then
  print("Error: GPS signal not found.")
  return
end

local currentX, currentY, currentZ = startX, startY, startZ

local function checkFuel()
  if turtle.getFuelLevel() == 0 then
    print("Error: Out of fuel.")
    return false
  end
  return true
end

local function withinBounds(x, y, z)
  return x >= startX and x < startX + length and
      y >= startY - depth and y <= startY and
      z >= startZ and z < startZ + width
end

local function moveForward()
  local newX, newZ = currentX, currentZ
  if turtle.forward() then
    if turtle.getFacing() == 0 then
      newX = currentX + 1
    elseif turtle.getFacing() == 1 then
      newZ = currentZ + 1
    elseif turtle.getFacing() == 2 then
      newX = currentX - 1
    elseif turtle.getFacing() == 3 then
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

local function digLayer()
  for w = 1, width do
    for l = 1, length - 1 do
      if not checkFuel() then return false end
      turtle.dig()
      if not moveForward() then return false end
    end
    if w < width then
      if w % 2 == 1 then
        turtle.turnRight()
        if not checkFuel() then return false end
        turtle.dig()
        if not moveForward() then return false end
        turtle.turnRight()
      else
        turtle.turnLeft()
        if not checkFuel() then return false end
        turtle.dig()
        if not moveForward() then return false end
        turtle.turnLeft()
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
