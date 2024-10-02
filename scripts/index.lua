-- Register the command completion function
local function completeScripts(shell, index, args)
  local completions = {}

  if index == 1 then
    -- First argument: the command (either 'install' or 'run')
    completions = { "install", "run" }

    local userInput = args[1] or ""
    local suggestions = {}

    -- Find matching completions based on partial input
    for _, command in ipairs(completions) do
      if command:sub(1, #userInput) == userInput then
        -- Suggest the remaining part of the command
        table.insert(suggestions, command:sub(#userInput + 1))
      end
    end

    return suggestions
  elseif index == 2 then
    -- Second argument: the folder name
    local folders = { "delveOS", "farmbot", "scripts" }

    local userInput = args[2] or ""
    local suggestions = {}

    -- Find matching folder names based on partial input
    for _, folder in ipairs(folders) do
      if folder:sub(1, #userInput) == userInput then
        -- Suggest the remaining part of the folder name
        table.insert(suggestions, folder:sub(#userInput + 1))
      end
    end

    return suggestions
  else
    -- No further arguments should be completed
    return {}
  end
end

-- Helper function to check if a table contains a value
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- Register the completion function with the shell
shell.setCompletionFunction("scripts.lua", completeScripts)

-- Utility function to download a file from GitHub, ignoring caching using headers
local function downloadFile(url, path)
  -- Set the HTTP request headers to disable caching
  local headers = {
    ["Cache-Control"] = "no-cache",
    ["Pragma"] = "no-cache"   -- Fallback for older servers
  }

  -- Make the HTTP request with custom headers
  local response = http.get(url, headers)
  if response then
    local content = response.readAll()
    response.close()

    local file = fs.open(path, "w")
    file.write(content)
    file.close()
  else
    print("Failed to download:", url)
    return false
  end
  return true
end

-- Function to install a script
local function installScript(folder)
  -- Special case: If installing 'scripts' itself
  if folder == "scripts" then
    print("Installing or updating the 'scripts' program itself...")

    local baseURL = "https://raw.githubusercontent.com/zackharley/cc-tweaked-scripts/main/scripts/"
    local indexURL = baseURL .. "index.lua"
    local packageURL = baseURL .. "package.json"

    -- Download the updated 'scripts.lua' and overwrite
    if downloadFile(indexURL, "scripts.lua") then
      print("Successfully updated 'scripts.lua'.")
    else
      error("Failed to update 'scripts.lua'.")
    end

    -- Fetch the package.json to get the new version number
    local tempPackagePath = "/scripts/scripts_package.json"
    if downloadFile(packageURL, tempPackagePath) then
      local packageFile = fs.open(tempPackagePath, "r")
      local packageData = textutils.unserializeJSON(packageFile.readAll())
      packageFile.close()

      if packageData and packageData.version then
        term.setTextColor(colors.green)
        print("New version: " .. packageData.version)
      else
        term.setTextColor(colors.red)
        print("Failed to get the version from the package.json")
      end
      term.setTextColor(colors.white)

      -- Clean up temp package.json file
      fs.delete(tempPackagePath)
    else
      print("Failed to download the package.json for 'scripts'.")
    end

    return
  end

  -- Step 1: Prepare URLs for other scripts
  local baseURL = "https://raw.githubusercontent.com/zackharley/cc-tweaked-scripts/main/" .. folder .. "/"
  local indexURL = baseURL .. "index.lua"
  local packageURL = baseURL .. "package.json"

  -- Step 2: Create directory for the script
  local scriptDir = "/scripts/" .. folder
  if not fs.exists(scriptDir) then
    fs.makeDir(scriptDir)
  end

  -- Step 3: Download package.json for version checking
  local packagePath = scriptDir .. "/package.json"
  local installedVersion = nil
  if fs.exists(packagePath) then
    local packageFile = fs.open(packagePath, "r")
    local installedPackage = textutils.unserializeJSON(packageFile.readAll())
    packageFile.close()
    installedVersion = installedPackage.version
  end

  -- Step 4: Download the new package.json
  if not downloadFile(packageURL, packagePath) then
    print("Failed to install script: " .. folder)
    return
  end

  -- Step 5: Parse new package.json and compare versions
  local packageFile = fs.open(packagePath, "r")
  local newPackage = textutils.unserializeJSON(packageFile.readAll())
  packageFile.close()

  if installedVersion then
    if installedVersion ~= newPackage.version then
      term.setTextColor(colors.yellow)
      print("Version changed from " .. installedVersion .. " to " .. newPackage.version)
    else
      term.setTextColor(colors.green)
      print("Script is up to date with version " .. installedVersion)
    end
  else
    term.setTextColor(colors.green)
    print("Installing script version " .. newPackage.version)
  end
  term.setTextColor(colors.white)

  -- Step 6: Download index.lua (main file)
  if not downloadFile(indexURL, scriptDir .. "/index.lua") then
    error("Failed to download index.lua for " .. folder)
    return
  end

  -- Step 7: Ask user if they want the script to run on startup
  if not fs.exists("startup.lua") then
    print("Do you want to run this script on startup? (y/n)")
    local input = read()
    if input == "y" then
      local startupFile = fs.open("startup.lua", "w")
      startupFile.write('shell.run("/scripts/' .. folder .. '/index.lua")')
      startupFile.close()
      print("Startup configured for script: " .. folder)
    end
  end

  print("Script " .. folder .. " installed successfully.")
end

-- Function to run an installed script
local function runScript(folder)
  -- Special case: Prevent recursion if trying to run 'scripts'
  if folder == "scripts" then
    print("Warning: Running 'scripts' from within 'scripts' could tear the fabric of space and time!")
    print("Preventing recursion to keep the universe intact.")
    return
  end

  local scriptPath = "/scripts/" .. folder .. "/index.lua"
  if fs.exists(scriptPath) then
    shell.run(scriptPath)
  else
    print("Script " .. folder .. " is not installed.")
  end
end

-- Main program logic
local args = { ... }

if #args < 2 then
  print("Usage:")
  print("scripts install <folder-name>  - Install a script")
  print("scripts run <folder-name>      - Run an installed script")
  return
end

local command = args[1]
local folder = args[2]

if command == "install" then
  installScript(folder)
elseif command == "run" then
  runScript(folder)
else
  print("Invalid command. Use 'install' or 'run'.")
end
