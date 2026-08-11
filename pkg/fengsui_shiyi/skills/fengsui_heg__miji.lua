local fengsui_heg__miji = fk.CreateSkill {
  name = "fengsui_heg__miji",
}

Fk:loadTranslationTable{
  ["fengsui_heg__miji"] = "秘计",
  [":fengsui_heg__miji"] = "结束阶段，你可以摸X张牌（X为你已损失体力值），然后你可以将等量手牌分配给其他角色。",

  ["#fengsui_heg__miji-give"] = "秘计：是否将%arg张手牌分配给其他角色？",

  ["$fengsui_heg__miji1"] = "此计，可歼敌精锐！",
  ["$fengsui_heg__miji2"] = "此举，可破敌之围！"
}

fengsui_heg__miji:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengsui_heg__miji.name) and player.phase == Player.Finish and
      player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getLostHp()
    player:drawCards(n, fengsui_heg__miji.name)
    if player.dead then return end
    local handCards = player:getCardIds("h")
    if #handCards >= n then
      room:askToYiji(player, {
        skill_name = fengsui_heg__miji.name,
        min_num = n,
        max_num = n,
        cards = handCards,
        targets = room:getOtherPlayers(player, false),
        cancelable = true,
      })
    end
  end,
})

return fengsui_heg__miji
