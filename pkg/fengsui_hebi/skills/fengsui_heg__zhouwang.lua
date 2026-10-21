local H = require "packages.fengsui.hegemony_util"

local zhouwang = fk.CreateSkill {
  name = "fengsui_heg__zhouwang",
  tags = { Skill.DeputyPlace, Skill.Compulsory },
}

local function slashCard(data)
  return data and data.card and (data.card.name == "slash" or data.card.trueName == "slash")
end

local function discardUniqueMost(room, user, skillName)
  if not user or user:isKongcheng() then return end
  local counts = {}
  for _, id in ipairs(user:getCardIds("h")) do
    local name = Fk:getCardById(id).trueName
    counts[name] = (counts[name] or 0) + 1
  end
  local best, bestName, tied = 0, nil, false
  for name, n in pairs(counts) do
    if n > best then best, bestName, tied = n, name, false
    elseif n == best then tied = true end
  end
  if tied or not bestName then return end
  local ids = table.filter(user:getCardIds("h"), function(id)
    return Fk:getCardById(id).trueName == bestName
  end)
  if #ids > 0 then room:throwCard(ids, skillName, user, user) end
end

zhouwang:addEffect(fk.TargetSpecified, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(zhouwang.name) and slashCard(data)
  end,
  on_use = function(self, _, _, player)
    discardUniqueMost(player.room, player, zhouwang.name)
  end,
})

zhouwang:addEffect(fk.TargetConfirmed, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasShownSkill(zhouwang.name) and slashCard(data) and
      data.from and data.from ~= player
  end,
  on_use = function(self, _, _, player, data)
    discardUniqueMost(player.room, data.from, zhouwang.name)
  end,
})

return zhouwang
