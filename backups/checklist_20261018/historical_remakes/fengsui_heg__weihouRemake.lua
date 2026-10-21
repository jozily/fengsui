local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local weihou = fk.CreateSkill{
  name = "fengsui_heg__weihouRemake",
}

local function retrialCards(player)
  return table.filter(player:getCardIds("e"), function(id)
    return not player:prohibitResponse(Fk:getCardById(id))
  end)
end

weihou:addEffect(fk.AskForRetrial, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weihou.name) and H.compareKingdomWith(target, player) and
      H.allGeneralsRevealed(player) and #retrialCards(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = retrialCards(player)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = tostring(Exppattern{ id = ids }),
      skill_name = weihou.name,
      prompt = "#fengsui_heg__weihouRemake-invoke::" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local old_card = data.card
    local new_card = Fk:getCardById(event:getCostData(self).cards[1])
    U.hideSkillGeneral(player, weihou.name)
    local same_color = new_card:compareColorWith(old_card)
    room:changeJudge{
      card = new_card,
      player = player,
      data = data,
      skillName = weihou.name,
      response = true,
    }
    if same_color and target:isAlive() then
      room:addPlayerMark(target, "fengsui_heg__weihouRemake_pending", 1)
    end
  end,
})

weihou:addEffect(fk.FinishRetrial, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("fengsui_heg__weihouRemake_pending") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local count = player:getMark("fengsui_heg__weihouRemake_pending")
    room:setPlayerMark(player, "fengsui_heg__weihouRemake_pending", 0)
    for _ = 1, count do
      if player.dead then return end
      H.askToHebiOrTransform(room, player, weihou.name, false)
    end
  end,
})

return weihou
