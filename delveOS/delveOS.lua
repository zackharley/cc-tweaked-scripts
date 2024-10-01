local configFilePath = "/config/delveOS.conf"

-- Function to save settings to a file
local function saveSettings(settings)
  local file = fs.open(configFilePath, "w")
  file.write(textutils.serialize(settings))
  file.close()
end

-- Function to load settings from a file
local function loadSettings()
  if fs.exists(configFilePath) then
    local file = fs.open(configFilePath, "r")
    local settings = textutils.unserialize(file.readAll())
    file.close()
    return settings
  else
    return nil
  end
end
local settings = loadSettings()

local terminalWidth, _ = term.getSize()
local version = "v1.0.0"

-- [BEGIN] Utilities
local function typewriter(text, delay, color, isCentered)
  term.setTextColor(color or colors.white) -- Default color to white if not provided

  for line in text:gmatch("[^\n]+") do     -- Split text by newline
    -- Calculate centered position if needed
    if isCentered then
      local lineLength = #line
      local x = math.floor((terminalWidth - lineLength) / 2) + 1 -- Calculate starting x position
      local _, y = term.getCursorPos()                           -- Get current y position
      term.setCursorPos(x, y)                                    -- Set cursor to center
    end

    -- Type out each character with a delay
    for i = 1, #line do
      term.write(line:sub(i, i)) -- Write one character at a time
      sleep(delay)               -- Delay between characters
    end

    -- Move to the next line after each line is printed
    local _, y = term.getCursorPos()
    term.setCursorPos(1, y + 1)
  end
end

local function drawProgressBar(x, y, length, percentage, color)
  term.setCursorPos(x, y)
  local filledLength = math.floor(percentage * length)

  -- Draw filled part
  term.setBackgroundColor(color)
  term.write(string.rep(" ", filledLength))

  -- Draw empty part
  term.setBackgroundColor(colors.gray)
  term.write(string.rep(" ", length - filledLength))

  -- Reset background color
  term.setBackgroundColor(colors.black)
end
-- [END] Utilities

local function flashWelcomeMessage()
  term.clear()
  term.setCursorPos(1, 6)

  typewriter("**********************", 0.05, colors.green, true)
  typewriter("* Welcome to delveOS *", 0.05, colors.green, true)
  typewriter("*  Deep Exploration  *", 0.05, colors.green, true)
  typewriter("*       System       *", 0.05, colors.green, true)
  typewriter("**********************", 0.05, colors.green, true)
  -- Display the version number in the center of a 22 character wide string using the typewriter function
  typewriter(version, 0.05, colors.green, true)

  sleep(2)
end

local function loadingWithProgressBar()
  local steps = {
    "Calibrating relays",
    "Syncing quantum arrays",
    "Warp stability: Optimal",
    "Linking core AI systems",
    "Neural sync: 99.99%",
    "Protocols secure",
    "Monitoring resources"
  }

  local totalSteps = #steps
  local progressBarWidth = 24 -- Width of the progress bar

  -- Display loading messages with progress bar
  for i, step in ipairs(steps) do
    term.clear()
    local x = math.floor((terminalWidth - #step) / 2) + 1 -- Calculate starting x position
    term.setCursorPos(x, 8)
    term.write(step)

    -- Calculate how much of the progress bar this step should fill
    local randomPause = math.random(1, 3)           -- Get random pause between 1 and 3 seconds
    local increments = 20                           -- Number of increments to smooth the animation
    local incrementDelay = randomPause / increments -- Delay per progress increment
    local startProgress = (i - 1) / totalSteps      -- Starting progress for this step
    local endProgress = i / totalSteps              -- Ending progress for this step

    -- Gradually fill the progress bar
    for j = 1, increments do
      local currentProgress = startProgress + (endProgress - startProgress) * (j / increments)
      drawProgressBar(2, 10, progressBarWidth, currentProgress, colors.green)
      sleep(incrementDelay) -- Wait proportional to the random pause time
    end
  end
end

local function showSuccessMessage()
  term.clear()
  term.setCursorPos(1, 6)
  typewriter("************************\n", 0.05, colors.green, true)
  typewriter("* delveOS initialized. *\n", 0.05, colors.green, true)
  typewriter("* All systems nominal. *\n", 0.05, colors.green, true)
  typewriter("************************\n", 0.05, colors.green, true)
  sleep(2)

  term.clear()
  term.setCursorPos(1, 6)
  typewriter("**********************\n", 0.05, colors.purple, true)
  typewriter("*                    *\n", 0.05, colors.purple, true)
  typewriter("*    Safe travels    *\n", 0.05, colors.purple, true)
  typewriter("*      explorer      *\n", 0.05, colors.purple, true)
  typewriter("*                    *\n", 0.05, colors.purple, true)
  typewriter("**********************\n", 0.05, colors.purple, true)
  sleep(3)
end

local function flashPrompt()
  while true do
    -- Display the "Press Enter" message
    term.clear()
    term.setCursorPos(1, 8)
    term.setTextColor(colors.white)
    print("      Press ENTER...      ")
    sleep(1)

    -- Clear the message (flashes off)
    term.clear()
    sleep(0.5)
  end
end

local function waitForEnter()
  while true do
    local event, key = os.pullEvent("key")
    if key == keys.enter then -- Check if the key pressed is Enter
      break                   -- Exit the loop and continue once Enter is pressed
    end
  end
end

local function promptEnterToContinue()
  term.clear()
  term.setCursorPos(1, 1)
  parallel.waitForAny(flashPrompt, waitForEnter)
end

local function initializeSystem()
  flashWelcomeMessage()
  loadingWithProgressBar()
  showSuccessMessage()
  promptEnterToContinue()
end

local function onboarding()
  term.clear()
  term.setCursorPos(1, 6)
  term.setTextColor(colors.green)

  -- Since it's your first time we need to setup the system
  typewriter("To get started we need to", 0.05, colors.green, true)
  typewriter("ask you a few questions.", 0.05, colors.green, true)
  sleep(1)
  term.clear()

  -- Ask for the user's name, ensure it's not empty
  local userName = ""
  while userName == "" do
    term.setCursorPos(1, 1)
    term.setTextColor(colors.green)
    print("Please enter your name:")
    term.setTextColor(colors.white)
    userName = read()
    if userName == "" then
      term.setCursorPos(1, 3)
      term.setTextColor(colors.red)
      print("Name cannot be empty! Please enter a valid name.")
      sleep(2)
      term.clear()
      term.setTextColor(colors.white)
    end
  end

  -- Ask for a preferred color (optional)
  -- term.clear()
  -- term.setCursorPos(1, 1)
  -- print("Choose a color theme (red, green, blue, or leave blank for white):")
  -- local colorChoice = read()

  -- -- Determine the color based on the user's choice
  -- local colorScheme = colors.white -- Default to white if blank
  -- if colorChoice == "red" then
  --   colorScheme = colors.red
  -- elseif colorChoice == "green" then
  --   colorScheme = colors.green
  -- elseif colorChoice == "blue" then
  --   colorScheme = colors.blue
  -- end

  -- Save the settings
  local settings = {
    name = userName,
    -- color = colorScheme
  }
  saveSettings(settings)

  -- Confirmation message
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.green)
  print("Thank you, " .. userName .. "!")
  print("Your settings have been saved.")
  sleep(2)
end

-- Example menu options
local menuOptions = {
  "Energy Monitor",
  "Storage Status",
  "AI System Control",
  "System Settings"
}

-- Function to render a pixel-art style top menu bar and buttons
local function renderPixelArtMenuBar()
  -- Draw a custom pixelated bar at the top (light gray background)
  paintutils.drawFilledBox(1, 1, terminalWidth, 1, colors.green)

  local titleText = "DelveOS"
  term.setCursorPos(math.floor((terminalWidth - #titleText) / 2), 1)
  term.setTextColor(colors.black)
  term.write(titleText)
  term.setBackgroundColor(colors.black)
end

-- Function to render the main menu with the pixel-art bar
local function renderMenu(selectedIndex)
  term.clear()
  renderPixelArtMenuBar() -- Draw the pixel-art style menu bar

  -- Display each option, highlight the selected one
  for i, option in ipairs(menuOptions) do
    term.setCursorPos(2, 3 + i) -- Adjust position below the bar
    local optionText = "[" .. i .. "] " .. option
    if i == selectedIndex then
      term.setTextColor(colors.green) -- Highlight the selected option
      print("> " .. optionText)
    else
      term.setTextColor(colors.white)
      print("  " .. optionText)
    end
  end
end

-- Function to handle menu navigation using arrow keys and enter
local function mainMenu()
  local selectedIndex = 1 -- Start with the first option selected
  local numOptions = #menuOptions

  renderMenu(selectedIndex)

  while true do
    local event, key = os.pullEvent("key") -- Listen for key events

    if key == keys.up then
      -- Move up in the menu
      selectedIndex = (selectedIndex - 1)
      if selectedIndex < 1 then
        selectedIndex = numOptions -- Wrap around to the last option
      end
      renderMenu(selectedIndex)
    elseif key == keys.down then
      -- Move down in the menu
      selectedIndex = (selectedIndex + 1)
      if selectedIndex > numOptions then
        selectedIndex = 1 -- Wrap around to the first option
      end
      renderMenu(selectedIndex)
    elseif key == keys.enter then
      -- Execute the selected option
      return selectedIndex -- Return the index of the selected option
    elseif key >= keys.one and key <= keys.nine then
      -- Handle number key input for quick selection (1-9)
      local optionNumber = key - keys.zero -- Get the number pressed
      if optionNumber >= 1 and optionNumber <= numOptions then
        return optionNumber                -- Return the selected option
      end
    end
  end
end

-- Example of what to do with the selected option
local function handleMenuSelection(selection)
  term.clear()
  term.setCursorPos(1, 1)
  if selection == 1 then
    print("Opening Energy Monitor...")
  elseif selection == 2 then
    print("Opening Storage Status...")
  elseif selection == 3 then
    print("Opening AI System Control...")
  elseif selection == 4 then
    print("Opening System Settings...")
  end
  sleep(2)    -- Give the user some time to see the message before returning to the menu
  return true -- Continue running the menu
end

-- Main program loop
local function runDelveOS()
  while true do
    local selectedOption = mainMenu()
    if not handleMenuSelection(selectedOption) then
      break -- Exit the loop if the user chooses to exit
    end
  end
end

local function main()
  -- initializeSystem()

  if not settings then
    onboarding()
    settings = loadSettings() -- Load the settings after onboarding
  end

  runDelveOS()
end

main()
