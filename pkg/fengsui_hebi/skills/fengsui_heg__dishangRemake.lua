local H = require "packages.fengsui.hegemony_util"

local dishang = fk.CreateSkill{
  name = "fengsui_heg__dishangRemake",
  tags = { Skill.Compulsory, Skill.MainPlace },
}

-- 阵法技的主动按钮仅用于发起阵法召唤。
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

local function getOtherBesieger(attacker, victim)
  local other
  if attacker:getNextAlive() == victim then
    other = victim:getNextAlive()
  elseif victim:getNextAlive() == attacker then
    other = victim:getLastAlive()
  end
  if other and H.inSiegeRelation(attacker, other, victim) then
    return other
  end
end

local function getEligibleActors(owner, attacker, victim)
  local other = getOtherBesieger(attacker, victim)
  if not other then return {} end

  local result = {}
  for _, actor in ipairs({ attacker, other, victim }) do
    if H.compareKingdomWith(actor, owner) then
      local counterparts = actor == victim and { attacker, other } or { victim }
      counterparts = table.filter(counterparts, function(p)
        return #commonSlots(actor, p) > 0
      end)
      if #counterparts > 0 then
        table.insert(result, { actor = actor, counterparts = counterparts })
      end
    end
  end
  return result
end

dishang:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target and data.to and player:hasSkill(dishang.name) and
      player:hasShownSkill(dishang.name) and #player.room.alive_players > 3 and
      data.card and data.card.is_damage_card and
      #getEligibleActors(player, target, data.to) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local entries = getEligibleActors(player, target, data.to)
    local actors = table.map(entries, function(entry) return entry.actor end)
    room:sortByAction(actors)

    for _, actor in ipairs(actors) do
      local entry = table.find(entries, function(item) return item.actor == actor end)
      local prompt
      if actor == data.to then
        prompt = "#fengsui_heg__dishangRemake-invoke-victim"
      else
        prompt = "#fengsui_heg__dishangRemake-invoke::" .. data.to.id
      end
      if room:askToSkillInvoke(actor, { skill_name = dishang.name, prompt = prompt }) then
        event:setCostData(self, entry)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local actor = cost.actor
    local counterparts = table.filter(cost.counterparts, function(p)
      return p:isAlive() and #commonSlots(actor, p) > 0
    end)
    if actor.dead or #counterparts == 0 then return end

    local counterpart = counterparts[1]
    if #counterparts > 1 then
      counterpart = room:askToChoosePlayers(actor, {
        targets = counterparts,
        min_num = 1,
        max_num = 1,
        skill_name = dishang.name,
        prompt = "#fengsui_heg__dishangRemake-counterpart",
        cancelable = false,
      })[1]
    end

    local choices = table.map(commonSlots(actor, counterpart), function(slot)
      return "fengsui_heg__dishangRemake_equip" .. slot
    end)
    if #choices == 0 then return end
    local choice = room:askToChoice(actor, {
      choices = choices,
      skill_name = dishang.name,
      prompt = "#fengsui_heg__dishangRemake-slot::" .. counterpart.id,
    })
    local slot = tonumber(choice:match("(%d+)$"))
    local actorCard = actor:getEquipments(slot)[1]
    local counterpartCard = counterpart:getEquipments(slot)[1]
    if not actorCard or not counterpartCard then return end

    room:moveCards(
      {
        ids = { actorCard },
        from = actor,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = actor,
        skillName = dishang.name,
      },
      {
        ids = { counterpartCard },
        from = counterpart,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = actor,
        skillName = dishang.name,
      }
    )
    data.disresponsive = true
  end,
})

return dishang
