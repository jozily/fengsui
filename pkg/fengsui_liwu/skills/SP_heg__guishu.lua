local guishu = fk.CreateSkill {
  name = "SP_heg__guishu",
}

guishu:addEffect("viewas", {
  pattern = "known_both,befriend_attacking",
  anim_type = "drawcard",
  interaction = function(self, player)
    local allChoices = { "befriend_attacking", "known_both" }
    local choices = table.filter(allChoices, function(name)
      return player:getMark("_SP_heg__guishu-turn") ~= name and player:canUse(Fk:cloneCard(name))
    end)
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = allChoices }
  end,
  card_filter = function(self, player, toSelect, selected)
    return #selected == 0 and Fk:getCardById(toSelect).suit == Card.Spade and
      Fk:currentRoom():getCardArea(toSelect) == Player.Hand
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = guishu.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "_SP_heg__guishu-turn", use.card.name)
  end,
})

Fk:loadTranslationTable {
  ["SP_heg__guishu"] = "鬼术",
  [":SP_heg__guishu"] = "出牌阶段，你可将一张黑桃手牌当【远交近攻】或【知己知彼】使用（不可与你此回合上一次以此法使用的牌相同）。",
  ["$SP_heg__guishu1"] = "契约已定！",
  ["$SP_heg__guishu2"] = "准备好，听候女王的差遣了吗？",
}

return guishu
