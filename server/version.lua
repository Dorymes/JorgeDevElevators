local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

local function parseVersion(ver)
    local parts = {}
    for part in string.gmatch(ver, "%d+") do
        table.insert(parts, tonumber(part))
    end
    return parts
end

local function isNewer(remote, localVer)
    local rParts = parseVersion(remote)
    local lParts = parseVersion(localVer)
    
    for i = 1, math.max(#rParts, #lParts) do
        local r = rParts[i] or 0
        local l = lParts[i] or 0
        if r > l then return true end
        if r < l then return false end
    end
    return false
end

CreateThread(function()
    if not Config.GithubRepo or Config.GithubRepo == 'USER/REPO' then 
        print('^3[JorgeDevElevators] Update Checker: GitHub repository not configured properly in config.lua!^0')
        return 
    end

    PerformHttpRequest('https://raw.githubusercontent.com/' .. Config.GithubRepo .. '/main/fxmanifest.lua', function(err, text, headers)
        if err == 200 then
            local versionPattern = "version '([%d%.]+)'"
            local remoteVersion = string.match(text, versionPattern)
            
            if remoteVersion and isNewer(remoteVersion, currentVersion) then
                print('^3----------------------------------------------------------------------^0')
                print('^3[JorgeDevElevators] Update Available! ^0')
                print('^3Current Version: ' .. currentVersion .. '^0')
                print('^3New Version: ' .. remoteVersion .. '^0')
                print('^3Download: https://github.com/' .. Config.GithubRepo .. '/releases/latest^0')
                print('^3----------------------------------------------------------------------^0')
            elseif not remoteVersion then
                 print('^1[JorgeDevElevators] Update Checker: Could not parse remote version!^0')
            else
                print('^2[JorgeDevElevators] is up to date (' .. currentVersion .. ')^0')
            end
        else
            print('^1[JorgeDevElevators] Update Checker: Error checking for updates (Status: ' .. err .. ')^0')
        end
    end, 'GET')
end)
