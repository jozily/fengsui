local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local wuli = fk.CreateSkill{
  name = "fengsui_heg__wuli",
  tags = { Skill.Compulsory },
}

local forbid_mark = "fengsui_heg__wuli_kingdoms-round"

wuli:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuli.name) and H.allGeneralsRevealed(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skill_is_deputy = U.getSkillPlace(player, wuli.name)
    if skill_is_deputy ~= nil then
      player:hideGeneral(not skill_is_deputy)
    end
    if data.from and H.getKingdom(data.from) ~= "unknown" then
      local kingdoms = player:getTableMark(forbid_mark)
      table.insertIfNeed(kingdoms, H.getKingdom(data.from))
      room:setPlayerMark(player, forbid_mark, kingdoms)
    end
  end,
})

wuli:addEffect("prohibit", {
  global = true,
  prohibit_response = function(self, player, card)
    local kingdoms = player:getTableMark(forbid_mark)
    if #kingdoms == 0 then return false end
    local event = player.room.logic:getCurrentEvent()
    local use_event = event and event:findParent(GameEvent.UseCard, true)
    if not use_event or not use_event.data.from then return false end
    return table.contains(kingdoms, H.getKingdom(use_event.data.from))
  end,
})

return wuli
