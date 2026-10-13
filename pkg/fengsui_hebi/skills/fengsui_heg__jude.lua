local H = require "packages.fengsui.hegemony_util"
local jude = fk.CreateSkill { name = "fengsui_heg__jude" }
jude:addEffect(fk.AfterAskForCardResponse, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    local response = data and data.result
    local effect = response and response.responseToEvent
    if not target or not target:isAlive() or not player:hasShownSkill(jude.name) or not response or not effect then
      return false
    end
    -- 两种情况都要覆盖：你响应他人的牌，或他人响应你的牌。
    local owner
    if effect.from == player then
      owner = target
    elseif target == player then
      owner = effect.from
    end
    return owner and owner:isAlive() and owner ~= player and H.compareKingdomWith(player, owner)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = jude.name, prompt = "#fengsui_heg__jude-invoke" }) then
      local effect = data.result.responseToEvent
      local owner = effect.from == player and target or effect.from
      event:setCostData(self, { owner = owner })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room, owner = player.room, event:getCostData(self).owner
    if not owner or owner.dead then return end
    local choice = room:askToChoice(owner, { choices = { "fengsui_heg__jude_draw", "fengsui_heg__jude_mark" }, skill_name = jude.name })
    if choice == "fengsui_heg__jude_draw" then
      local id = room.draw_pile[1]
      if id then room:showCards({ id }, owner); room:obtainCard(owner, id, true, fk.ReasonPrey, owner, jude.name) end
      if owner:isAlive() and H.hasGeneral(owner, true) then
        H.transformGeneral(room, owner, false, false, 1, jude.name)
      end
    else
      H.addHegMark(owner, "yinyangfish")
    end
  end,
})
return jude
