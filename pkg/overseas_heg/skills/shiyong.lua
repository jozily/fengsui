local shiyong = fk.CreateSkill{
  name = "os_heg__shiyong",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player)
    return "os_heg__shiyong" .. player:getMark("os_heg__yaowu-noclear")
  end,
}

Fk:loadTranslationTable{
  ["os_heg__shiyong"] = "恃勇",
  [":os_heg__shiyong"] = "锁定技，当你受到伤害后，1级：若造成伤害的牌不为红色，你摸一张牌；2级：若造成伤害的牌不为黑色，伤害来源摸一张牌。",

  ["os_heg__shiyong0"] = "锁定技，当你受到伤害后，若造成伤害的牌不为红色，你摸一张牌。",
  ["os_heg__shiyong1"] = "锁定技，当你受到伤害后，若造成伤害的牌不为黑色，伤害来源摸一张牌。",

  ["$os_heg__shiyong1"] = "你们不要笑得太早。",
  ["$os_heg__shiyong2"] = "哼，不痛不痒。",
}

shiyong:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shiyong.name) and data.card then
      if player:getMark("os_heg__yaowu-noclear") > 0 then
        return data.card.color ~= Card.Black and data.from and data.from:isAlive()
      else
        return data.card.color ~= Card.Red
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(shiyong.name)
    if player:getMark("os_heg__yaowu-noclear") > 0 then
      room:notifySkillInvoked(player, shiyong.name, "negative")
      data.from:drawCards(1, shiyong.name)
    else
      room:notifySkillInvoked(player, shiyong.name, "drawcard")
      player:drawCards(1, shiyong.name)
    end
  end,
})

return shiyong
