local H = require "packages.fengsui.hegemony_util"

local dishang = fk.CreateSkill{
  name = "fengsui_heg__dishang",
  tags = { Skill.MainPlace },
}

-- 阵法技的主动按钮仅用于发起阵法召唤。
dishang:addEffect("arraysummon", { array_type = "siege" })

-- 判定区与五个装备副区域中，双方都有牌的区域
local function commonZones(from, to)
  local zones = {}
  if #from:getCardIds("j") > 0 and #to:getCardIds("j") > 0 then
    table.insert(zones, { kind = "judge", key = "fengsui_heg__dishang_judge" })
  end
  for slot = 1, 5 do
    if #from:getEquipments(slot) > 0 and #to:getEquipments(slot) > 0 then
      table.insert(zones, { kind = "equip", slot = slot, key = "fengsui_heg__dishang_equip" .. slot })
    end
  end
  return zones
end

dishang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not (target and data.to and data.card) then return false end
    if not player:hasShownSkill(dishang.name) then return false end
    if #player.room.alive_players <= 3 then return false end
    if not data.card.is_damage_card then return false end
    -- 使用者须为与本技能拥有者同势力的围攻角色
    if not H.compareKingdomWith(target, player) then return false end
    if not H.inSiegeRelation(target, target, data.to) then return false end
    return #commonZones(target, data.to) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = dishang.name,
      prompt = "#fengsui_heg__dishang-invoke::" .. data.to.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local actor, victim = target, data.to
    if actor.dead or victim.dead then return end

    local zones = commonZones(actor, victim)
    if #zones == 0 then return end
    local zone = zones[1]
    if #zones > 1 then
      local choice = room:askToChoice(actor, {
        choices = table.map(zones, function(z) return z.key end),
        skill_name = dishang.name,
        prompt = "#fengsui_heg__dishang-slot::" .. victim.id,
      })
      zone = table.find(zones, function(z) return z.key == choice end) or zones[1]
    end

    local actorCard, victimCard
    if zone.kind == "judge" then
      if #actor:getCardIds("j") == 0 or #victim:getCardIds("j") == 0 then return end
      actorCard = room:askToChooseCard(actor, {
        target = actor,
        flag = "j",
        skill_name = dishang.name,
        prompt = "#fengsui_heg__dishang-pick-own",
      })
      victimCard = room:askToChooseCard(actor, {
        target = victim,
        flag = "j",
        skill_name = dishang.name,
        prompt = "#fengsui_heg__dishang-pick::" .. victim.id,
      })
    else
      actorCard = actor:getEquipments(zone.slot)[1]
      victimCard = victim:getEquipments(zone.slot)[1]
    end
    if not actorCard or not victimCard then return end

    room:moveCardTo(
      { actorCard, victimCard }, Card.DiscardPile, nil,
      fk.ReasonDiscard, dishang.name, nil, true, actor
    )
    data.disresponsive = true
  end,
})

return dishang
