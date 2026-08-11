local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local fuzai = fk.CreateSkill{
  name = "fengsui_heg__fuzai",
  tags = { Skill.Compulsory },
}

local function curioCount(player)
  return #table.filter(player:getEquipCards(), function(card)
    return card.package and card.package.name == "nine_variations"
  end)
end

local function hasVirtualCauldron(player)
  return #player:getEquipments(Card.SubtypeTreasure) == 0
end

local function checkVictory(player)
  if hasVirtualCauldron(player) and curioCount(player) >= 3 and H.getKingdom(player) ~= "unknown" then
    player.room:gameOver(H.getKingdom(player))
  end
end

local victorySpec = {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuzai.name) and hasVirtualCauldron(player) and curioCount(player) >= 3
  end,
  on_use = function(self, event, target, player, data)
    checkVictory(player)
  end,
}
fuzai:addEffect(fk.AfterCardsMove, victorySpec)
fuzai:addEffect(fk.GeneralRevealed, victorySpec)

fuzai:addEffect(fk.AfterCardsMove, {
  global = true,
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(fuzai.name) then return false end
    return table.find(data, function(move)
      return move.to and move.to ~= player and move.toArea == Card.PlayerEquip and
        table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId).name == "nine_tripod_cauldrons"
        end)
    end) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if H.hasGeneral(player, true) then table.insert(choices, "fengsui_heg__fuzai_discard") end
    if U.getLegalTargetNum(player, Fk:cloneCard("part_ways")) > 0 then
      table.insert(choices, "fengsui_heg__fuzai_partways")
    end
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(player, {
      choices = choices,
      skill_name = fuzai.name,
    })
    if choice == "fengsui_heg__fuzai_discard" then
      local cards = player:getCardIds("e")
      if #cards > 0 then room:throwCard(cards, fuzai.name, player, player) end
      if player:isAlive() and H.hasGeneral(player, true) then H.transformGeneral(room, player, false, false) end
    else
      room:askToUseVirtualCard(player, {
        name = "part_ways",
        skill_name = fuzai.name,
        cancelable = false,
        extra_data = { bypass_times = true },
      })
    end
  end,
})

return fuzai
