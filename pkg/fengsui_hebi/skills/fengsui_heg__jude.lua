local H = require "packages.fengsui.hegemony_util"
local yunde = fk.CreateSkill { name = "fengsui_heg__jude" }
yunde:addEffect(fk.AfterAskForCardResponse, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local effect = data and data.result and data.result.responseToEvent
    local owner = effect and effect.from
    return target and target:isAlive() and player:hasSkill(yunde.name) and data.result and owner and owner:isAlive() and owner ~= player and H.compareKingdomWith(player, owner)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = yunde.name, prompt = "#fengsui_heg__jude-invoke" }) then
      event:setCostData(self, { owner = data.result.responseToEvent.from })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room, owner = player.room, event:getCostData(self).owner
    if not owner or owner.dead then return end
    local choice = room:askToChoice(owner, { choices = { "fengsui_heg__jude_draw", "fengsui_heg__jude_mark" }, skill_name = yunde.name })
    if choice == "fengsui_heg__jude_draw" then
      local id = room.draw_pile[#room.draw_pile]
      if id then room:showCards({ id }, owner); room:obtainCard(owner, id, true, fk.ReasonPrey, owner, yunde.name) end
      if owner:isAlive() and owner.deputyGeneral then H.transformGeneral(room, owner, false, false, 1, yunde.name) end
    else
      H.addHegMark(owner, "yinyangfish")
    end
  end,
})
return yunde
