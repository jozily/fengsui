local overlayGenerals = {
  "heg__jiananfeng",
  "heg__simajiong",
  "heg__simawei",
  "heg__simayij",
  "heg__simaying",
  "heg__simayong",
  "heg__simayue",
  "heg__sunxiuj",
  "heg__yangjun",
}

local nineVariationsAudio = {
  overbearing = true,
  part_ways = true,
  reveal_intention = true,
  tricky_heist = true,
  unworthy_continuation = true,
}

local function fengsuiPackageProxy(original)
  local proxy = {}
  for key, value in pairs(original) do
    proxy[key] = value
  end
  proxy.extensionName = "fengsui"
  proxy._fengsuiOriginalPackage = original
  setmetatable(proxy, getmetatable(original))
  return proxy
end

local function findGeneral(packages, name)
  if Fk.generals[name] then return Fk.generals[name] end
  for _, package in ipairs(packages or {}) do
    for _, general in ipairs(package.generals or {}) do
      if general.name == name then return general end
    end
  end
end

return function(packages)
  local applied = 0
  for _, name in ipairs(overlayGenerals) do
    local general = findGeneral(packages, name)
    if general and general.package and general.package.extensionName ~= "fengsui" then
      general.package = fengsuiPackageProxy(general.package)
      applied = applied + 1
    elseif general and general.package and general.package.extensionName == "fengsui" then
      applied = applied + 1
    end
  end

  assert(applied == #overlayGenerals, "fengsui audio overlay must bind all official hegemony generals")

  if not Fk._fengsuiCardPreviewAudioRedirected then
    local originalCardExtension = GetCardExtensionByName
    GetCardExtensionByName = function(cardName)
      if nineVariationsAudio[cardName] then return "fengsui" end
      return originalCardExtension(cardName)
    end
    Fk._fengsuiCardPreviewAudioRedirected = true
  end
end
