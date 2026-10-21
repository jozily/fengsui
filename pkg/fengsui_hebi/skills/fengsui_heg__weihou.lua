local H = require "packages.fengsui.hegemony_util"

local weihou = fk.CreateSkill{
  name = "fengsui_heg__weihou",
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
      prompt = "#fengsui_heg__weihou-invoke::" .. target.id,
      cancelable = true,
    })
    if #cards > 0 then
      -- 维后暗置技能所在武将牌的另一张武将牌。
      local place = require("packages.fengsui.pkg.fengsui_hebi.util").getSkillPlace(player, weihou.name)
      if place == nil or not H.allGeneralsRevealed(player) then return false end
      event:setCostData(self, { cards = cards, hide_deputy = not place })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost = event:getCostData(self)
    local new_card = Fk:getCardById(cost.cards[1])
    player:hideGeneral(cost.hide_deputy)
    room:changeJudge{
      card = new_card,
      player = player,
      data = data,
      skillName = weihou.name,
      response = true,
    }
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__weihou-hide"] = "维后：暗置另一张武将牌",
}

return weihou
