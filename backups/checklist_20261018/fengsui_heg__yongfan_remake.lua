-- ==================== pkg\fengsui\skills\yanrou.lua ====================
local H = require "packages.fengsui.hegemony_util"

local yongfan = fk.CreateSkill{
  name = "fengsui_heg__yongfan",
}
yongfan:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yongfan.name) and
      data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yongfan.name,
      prompt = "#fengsui_heg__yongfan-invoke::" .. data.from.id .. ":" ..
        (H.compareKingdomWith(data.from, player) and "以逸待劳" or "远交近攻"),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if H.compareKingdomWith(data.from, player) then
      room:useVirtualCard("await_exhausted", nil, player, { player, data.from }, yongfan.name, true)
    else
      room:useVirtualCard("befriend_attacking", nil, player, data.from, yongfan.name, true)
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__yongfan"] = "雍番",
  [":fengsui_heg__yongfan"] = "当你受到伤害后，若伤害来源与你势力不同/相同，你可视为对其使用一张【远交近攻】/【以逸待劳】。",
  ["#fengsui_heg__yongfan-invoke"] = "雍番：是否视为对 %dest 使用【%arg】？",
}

return yongfan
