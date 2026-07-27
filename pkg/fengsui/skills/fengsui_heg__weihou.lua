local H = require "packages.hegemony.util"
local U = require "packages.hegemony.pkg.fengsui.util"

local weihou = fk.CreateSkill{
  name = "fengsui_heg__weihou",
}

weihou:addEffect(fk.AskForRetrial, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(weihou.name) and H.compareKingdomWith(target, player) and
      H.allGeneralsRevealed(player) and #player:getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = tostring(Exppattern{ id = player:getCardIds("e") }),
      skill_name = weihou.name,
      prompt = "#fengsui_heg__weihou-invoke::" .. target.id,
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
      H.askToHebiOrTransform(room, target, weihou.name, false)
    end
  end,
})

return weihou
