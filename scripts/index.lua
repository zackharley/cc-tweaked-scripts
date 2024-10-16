local parameters = {
  ["run "] = {
    ["delveOS"] = {},
    ["farmbot"] = {},
    ["scripts"] = {},
  },
  ["install "] = {
    ["delveOS"] = {},
    ["farmbot"] = {},
    ["scripts"] = {},
  }
}

local function tabCompletionFunction(shell, parNumber, curText, lastText)
  -- Check that the parameters entered so far are valid:
  local curParam = parameters
  for i = 2, #lastText do
    if curParam[lastText[i] .. " "] then
      curParam = curParam[lastText[i] .. " "]
    else
      return {}
    end
  end

  -- Check for suitable words for the current parameter:
  local results = {}
  for word, _ in pairs(curParam) do
    if word:sub(1, #curText) == curText then
      results[#results + 1] = word:sub(#curText + 1)
    end
  end
  return results
end

-- Register the completion function with the shell
shell.setCompletionFunction("scripts.lua", tabCompletionFunction)

-- Utility function to download a file from GitHub, ignoring caching using headers
local function downloadFile(url, path)
  -- Set the HTTP request headers to disable caching
  local headers = {
    ["Cache-Control"] = "no-cache",
    ["Pragma"] = "no-cache" -- Fallback for older servers
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

-- Function to check for script updates
local function checkForUpdate()
  local packageURL = "https://raw.githubusercontent.com/zackharley/cc-tweaked-scripts/main/scripts/package.json"
  local tempPackagePath = "/scripts/scripts_package_check.json"

  -- Download the latest version of package.json to check for updates
  if downloadFile(packageURL, tempPackagePath) then
    local packageFile = fs.open(tempPackagePath, "r")
    local packageData = textutils.unserializeJSON(packageFile.readAll())
    packageFile.close()
    fs.delete(tempPackagePath)

    -- Check if local version is available
    if fs.exists("/scripts/scripts_package.json") then
      local localPackageFile = fs.open("/scripts/scripts_package.json", "r")
      local localPackageData = textutils.unserializeJSON(localPackageFile.readAll())
      localPackageFile.close()

      if packageData and localPackageData and packageData.version ~= localPackageData.version then
        print("Update available! Install with")
        term.setTextColor(colors.yellow)
        print("`scripts install scripts`")
        term.setTextColor(colors.white)
        return true -- An update is available
      end
    end
  else
    print("Failed to check for updates.")
  end
  return false -- No update is required
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

local command = args[1]
local folder = args[2]

local isInstallingUpdate = command == "install" and folder == "scripts"
-- Check for updates before proceeding
if not isInstallingUpdate and checkForUpdate() then
  return -- Abort if an update is available
end

if #args < 2 then
  print("Usage:")
  print("scripts install <folder-name>  - Install a script")
  print("scripts run <folder-name>      - Run an installed script")
  return
end

term.clear()
term.setCursorPos(1, 1)
if command == "install" then
  installScript(folder)
elseif command == "run" then
  runScript(folder)
else
  print("Invalid command. Use 'install' or 'run'.")
end
