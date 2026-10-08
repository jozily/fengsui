local H = require "packages.fengsui.hegemony_util"
local qiongbu = fk.CreateSkill { name = "fengsui_heg__qiongbu" }

local function canTrigger(target, player)
  return target and target ~= player and target:isAlive() and player:hasSkill("fengsui_heg__qiongbu") and
    player:getMark("fengsui_heg__qiongbu_resolving") == 0 and player:getMark("fengsui_heg__qiongbu-turn") == 0 and
    H.getGeneralsRevealedNum(target) ~= H.getGeneralsRevealedNum(player)
end

local function adjust(self, target, player)
  local room = player.room
  room:setPlayerMark(player, "fengsui_heg__qiongbu_resolving", 1)
  local wanted = H.getGeneralsRevealedNum(player)
  while H.getGeneralsRevealedNum(target) < wanted do
    if target.general == "anjiang" then target:revealGeneral(false)
    elseif target.deputyGeneral == "anjiang" then target:revealGeneral(true)
    else break end
  end
  while H.getGeneralsRevealedNum(target) > wanted do
    if target.deputyGeneral ~= "anjiang" then target:hideGeneral(true)
    elseif target.general ~= "anjiang" then target:hideGeneral(false)
    else break end
  end
  room:setPlayerMark(player, "fengsui_heg__qiongbu_resolving", 0)
  room:drawCards(player, 2, self.name)
end

for _, event in ipairs({ fk.GeneralShown, fk.GeneralHidden }) do
  qiongbu:addEffect(event, {
    global = true,
    can_trigger = function(self, _, target, player) return canTrigger(target, player) end,
    on_trigger = function(self, event, target, player, data)
      local room = player.room
      room:setPlayerMark(player, "fengsui_heg__qiongbu-turn", 1)
      if room:askToSkillInvoke(player, { skill_name = self.name, prompt = "#fengsui_heg__qiongbu-adjust::" .. target.id }) then
        adjust(self, target, player)
      else
        room:damage { to = target, damage = 1, skillName = self.name }
      end
      return true
    end,
  })
end
qiongbu:addEffect(fk.TurnStart, { global = true,
  on_use = function(self, _, target) target.room:setPlayerMark(target, "fengsui_heg__qiongbu-turn", 0) end,
})
return qiongbu
