local extension = Package:new("fengsui_mode", Package.SpecialPack)
extension.extensionName = "fengsui"
extension.game_modes_whitelist = { "fengsui_heg__mode" }

local officialPackages = require "packages/fengsui/pkg/hegemony_packages"
local officialMode
for _, package in ipairs(officialPackages) do
  for _, mode in ipairs(package.game_modes or {}) do
    if mode.name == "new_heg_mode" then
      officialMode = mode
      break
    end
  end
  if officialMode then break end
end

local mode = require "packages/fengsui/pkg/fengsui_mode/fengsuihegemony"
local officialWhitelist = {}
if officialMode and type(officialMode.whitelist) == "table" then
  table.insertTableIfNeed(officialWhitelist, officialMode.whitelist)
end

for _, package in ipairs(officialPackages) do
  if table.contains(officialWhitelist, package.name) then
    package.game_modes_whitelist = package.game_modes_whitelist or {}
    table.insertIfNeed(package.game_modes_whitelist, mode.name)
  end
end

local fengsuiPackages = {
  "fengsui_hebi", "fengsui_cards", "fengsui_liwu", "fengsui_shiyi", "fengsui_effect", "fengsui_mode",
}
mode.whitelist = {}
table.insertTableIfNeed(mode.whitelist, officialWhitelist)
table.insertTableIfNeed(mode.whitelist, fengsuiPackages)

-- Public engine extension point: expose Fengsui packages in the official mode
-- without editing the official hegemony package.
Fk:addWhiteListPack("new_heg_mode", fengsuiPackages)
Fk._fengsuiModeOfficialPackages = officialWhitelist
Fk._fengsuiModePackages = fengsuiPackages

extension:loadSkillSkelsByPath("./packages/fengsui/pkg/fengsui_mode/skills")
extension:addGameMode(mode)

return extension
