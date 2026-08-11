local H = require "packages.fengsui.hegemony_util"

local jiaojin = fk.CreateSkill {
  name = "fengsui_heg__jiaojin",
}

Fk:loadTranslationTable{
  ["fengsui_heg__jiaojin"] = "骄矜",
  [":fengsui_heg__jiaojin"] = "当你受到伤害后，若伤害来源与你的武将牌明置状态不同且你的武将牌均明置，你可以暗置此武将牌并令其执行一个军令。若其不执行，你回复1点体力。",
  ["#fengsui_heg__jiaojin-invoke"] = "骄矜：是否暗置此武将牌，令 %dest 执行一个军令？",

  ["$fengsui_heg__jiaojin1"] = "恩情惩刑，皆是本公主的赏赐。",
  ["$fengsui_heg__jiaojin2"] = "本公主要做何事，还需你们说教？",
}

local function sameRevealState(first, second)
  return first and second and
    (first.general == "anjiang") == (second.general == "anjiang") and
    (first.deputyGeneral == "anjiang") == (second.deputyGeneral == "anjiang")
end

jiaojin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaojin.name) and
      H.allGeneralsRevealed(player) and data.from and data.from:isAlive() and
      not sameRevealState(player, data.from)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jiaojin.name,
      prompt = "#fengsui_heg__jiaojin-invoke::" .. data.from.id,
    }) then
      event:setCostData(self, { tos = { data.from } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local from = data.from
    H.hideBySkillName(player, jiaojin.name)
    if player.dead or from.dead then return end
    local succeeded = H.askToCommand(player, {
      tos = { from },
      skill_name = jiaojin.name,
    })
    if not succeeded and player:isWounded() then
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = jiaojin.name,
      }
    end
  end,
})

return jiaojin
