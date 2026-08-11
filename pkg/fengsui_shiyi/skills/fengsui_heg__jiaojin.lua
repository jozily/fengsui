local fengsui_heg__jiaojin = fk.CreateSkill {
  name = "fengsui_heg__jiaojin",
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiaojin"] = "骄矜",
  [":fengsui_heg__jiaojin"] = "当你受到男性角色造成的伤害时，你可以弃置一张装备牌，令此伤害-1。",

  ["#fengsui_heg__jiaojin-invoke"] = "骄矜：你可以弃置一张装备牌，令你受到的伤害-1",

  ["$fengsui_heg__jiaojin1"] = "就凭你，还想算计于我？",
  ["$fengsui_heg__jiaojin2"] = "是谁借给你的胆子？"
}

fengsui_heg__jiaojin:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengsui_heg__jiaojin.name) and
      data.from and data.from:isMale() and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      skill_name = fengsui_heg__jiaojin.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      cancelable = true,
      pattern = ".|.|.|.|.|equip",
      prompt = "#fengsui_heg__jiaojin-invoke",
      skip = true,
      })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
    player.room:throwCard(event:getCostData(self).cards, fengsui_heg__jiaojin.name, player, player)
  end,
})

return fengsui_heg__jiaojin
