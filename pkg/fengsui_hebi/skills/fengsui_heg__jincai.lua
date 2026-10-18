local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jincai = fk.CreateSkill { name = "fengsui_heg__jincai" }

jincai:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, _, target, player, data)
    return target and data and data.to == player and data.card and data.card.color == Card.Red and
      player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = "#fengsui_heg__jincai-invoke::" .. target.id,
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local choices = { "fengsui_heg__jincai_obtain" }
    if H.allGeneralsRevealed(target) then table.insert(choices, 1, "fengsui_heg__jincai_hide") end
    local choice = room:askToChoice(target, {
      choices = choices, skill_name = self.name,
      prompt = "#fengsui_heg__jincai-choice::" .. player.id,
    })
    if choice == "fengsui_heg__jincai_hide" then
      local place = room:askToChoice(target, {
        choices = { "fengsui_heg__jincai_main", "fengsui_heg__jincai_deputy" },
        skill_name = self.name, prompt = "#fengsui_heg__jincai-place",
      })
      target:hideGeneral(place == "fengsui_heg__jincai_deputy")
      U.prohibitReveal(target, place == "fengsui_heg__jincai_deputy", self.name, "turn")
      data.nullifiedTargets = data.nullifiedTargets or {}
      table.insertIfNeed(data.nullifiedTargets, target)
    else
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, self.name)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__jincai-invoke"] = "矜才：是否令 %dest 选择一项？",
  ["fengsui_heg__jincai_hide"] = "暗置一张武将牌且此牌无效",
  ["fengsui_heg__jincai_obtain"] = "令矜才拥有者获得此牌",
  ["fengsui_heg__jincai_main"] = "暗置主将",
  ["fengsui_heg__jincai_deputy"] = "暗置副将",
  ["#fengsui_heg__jincai-place"] = "矜才：选择暗置的武将牌",
}

return jincai
