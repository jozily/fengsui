-- 暗流（陆昙）
-- 锁定技，当你受到或造成伤害后，若受伤角色：副将明置，其暗置变更副将，
-- 否则其摸暗置武将牌数量的牌。
local H = require "packages.fengsui.hegemony_util"

local anliu = fk.CreateSkill {
  name = "fengsui_heg__anliu",
  tags = { Skill.Compulsory },
}

local function hiddenGeneralCount(player)
  local n = 0
  if player.general == "anjiang" then n = n + 1 end
  if player.deputyGeneral == "anjiang" then n = n + 1 end
  return n
end

local function resolveVictim(self, room, victim)
  if not victim or not victim:isAlive() then return end
  if victim.deputyGeneral and victim.deputyGeneral ~= "anjiang" then
    -- 副将明置：暗置变更副将
    H.transformGeneral(room, victim, false, true, 1, self.name)
  else
    local n = hiddenGeneralCount(victim)
    if n > 0 then
      room:drawCards(victim, n, self.name)
    end
  end
end

anliu:addEffect(fk.Damage, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data and data.from == player
  end,
  on_use = function(self, event, target, player, data)
    resolveVictim(self, player.room, data.to)
  end,
})

anliu:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data and data.to == player
  end,
  on_use = function(self, event, target, player, data)
    resolveVictim(self, player.room, data.to)
  end,
})

return anliu
