-- ==================== pkg\fengsui\skills\yanrou.lua ====================
local H = require "packages.hegemony.util"

local yongfan = fk.CreateSkill{
  name = "fengsui_heg__yongfan",
}
yongfan:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yongfan.name) and
      data.from and not data.from.dead and not H.compareKingdomWith(data.from, player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yongfan.name,
      prompt = "#fengsui_heg__yongfan-invoke::" .. data.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local trick = Fk:cloneCard("befriend_attacking")
    trick.skillName = yongfan.name
    room:useCard{
      from = player,
      tos = {data.from},
      card = trick,
    }
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__yongfan"] = "雍番",
  [":fengsui_heg__yongfan"] = "当你受到伤害后，若伤害来源与你不为同一势力，你可视为对其使用一张【远交近攻】。",
  ["#fengsui_heg__yongfan-invoke"] = "雍番：是否视为对 %dest 使用一张【远交近攻】？",
}

return yongfan
