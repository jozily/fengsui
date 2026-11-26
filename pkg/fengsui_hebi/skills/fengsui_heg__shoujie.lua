local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local shoujie = fk.CreateSkill{
  name = "fengsui_heg__shoujie",
  tags = { Skill.Compulsory },
}

shoujie:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shoujie.name) and
      data.card and data.card.type == Card.TypeTrick and
      data.use and #data.use.tos > 1 and #player:getCardIds("he") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    if not player:isKongcheng() then table.insert(choices, "shoujie_hand") end
    if #player:getCardIds("e") > 0 then table.insert(choices, "shoujie_equip") end
    local choice = room:askToChoice(player, {
      choices = choices,
      prompt = "#fengsui_heg__shoujie-protect",
      skill_name = shoujie.name,
    })
    event:setCostData(self, { choice = choice })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local cards = {}
    if choice == "shoujie_hand" then cards = player:getCardIds("h")
    elseif choice == "shoujie_equip" then cards = player:getCardIds("e") end
    local c_len = #cards
    room:throwCard(cards, shoujie.name, player, player)

    local target_mates = data:getAllTargets()
    local cancel_num = math.min(c_len, #target_mates)
    if cancel_num > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = target_mates,
        min_num = cancel_num,
        max_num = cancel_num,
        prompt = "#fengsui_heg__shoujie-cancel-tos",
        skill_name = shoujie.name,
        cancelable = false,
      })
      for _, p in ipairs(tos) do
        data:cancelTarget(p)
      end
    end

    -- 武将牌均明置时：摸等量张牌并暗置此武将牌
    if H.allGeneralsRevealed(player) then
      player:drawCards(c_len, shoujie.name)
      if not U.hideSkillGeneral(player, shoujie.name) then
        if player.general ~= "anjiang" then player:hideGeneral(false) end
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["fengsui_heg__shoujie"] = "守节",
  [":fengsui_heg__shoujie"] = "锁定技，当你成为一张多目标锦囊牌的目标后，你弃置一个区域的所有牌并取消其中等量名角色的目标。若你武将牌均明置，你摸等量张牌并暗置此武将牌。",
  ["#fengsui_heg__shoujie-protect"] = "守节：弃置一个区域的所有牌，取消此锦囊牌中等量名角色的目标",
  ["shoujie_hand"] = "弃置所有手牌",
  ["shoujie_equip"] = "弃置所有装备区牌",
  ["#fengsui_heg__shoujie-cancel-tos"] = "守节：请选择要从此锦囊中取消的目标",
}

return shoujie
