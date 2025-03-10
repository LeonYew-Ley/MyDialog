
local class = require('middleclass')
require('common/tableutil')
local Entrance = class('entrance')
function Entrance : initialize(token)
    App.IsStudioClass = true
    local pkgName = NEXT_STUDIO_BASE_SCRIPTS_LOC..'nextstudio_fsync_base'
    local pkg = require(pkgName)
    local modName = App.ModName
    local modPackageJson = GetPackageJson(modName)
    if modPackageJson ~= nil then
        local quality = modPackageJson.quality or 0
        App:SetRenderQualityLevel(tonumber(quality))
    end
        pkg:new(token,modName)
    end
return Entrance