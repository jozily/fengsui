local H = require "packages.hegemony.util"

local dishang = fk.CreateSkill{
  name = "fengsui_heg__dishang",
  tags = { Skill.MainPlace },
}

dishang:addEffect("arraysummon", { array_type = "siege" })

local function commonSlots(from, to)
  local slots = {}
  for slot = 1, 5 do
    if #from:getEquipments(slot) > 0 and #to:getEquipments(slot) > 0 then
      table.insert(slots, slot)
    end
  end
  return slots
end

dishang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and data.to and player:hasSkill(dishang.name) and
      player:hasShownSkill(dishang.name) and #player.room.alive_players > 3 and
      data.card and data.card.is_damage_card and
      H.compareKingdomWith(target, player) and
      H.inSiegeRelation(target, player, data.to) and
      #commonSlots(target, data.to) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = dishang.name,
      prompt = "#fengsui_heg__dishang-invoke::" .. data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.map(commonSlots(target, data.to), function(slot)
      return "fengsui_heg__dishang_equip" .. slot
    end)
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = dishang.name,
      prompt = "#fengsui_heg__dishang-slot::" .. data.to.id,
    })
    local slot = tonumber(choice:match("(%d+)$"))
    local from_card = target:getEquipments(slot)[1]
    local to_card = data.to:getEquipments(slot)[1]
    room:moveCards(
      {
        ids = { from_card },
        from = target,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = target,
        skillName = dishang.name,
      },
      {
        ids = { to_card },
        from = data.to,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = target,
        skillName = dishang.name,
      }
    )
    data.disresponsive = true
  end,
})

return dishang
