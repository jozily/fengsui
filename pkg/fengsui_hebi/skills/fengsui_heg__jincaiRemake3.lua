-- 矜才·旧版存档（2026-11-14）：成为目标后，令使用者二选一——暗置一张武将牌否则此牌对你无效 / 令你获得此牌。
-- 现役版本改为「使用者武将牌均明置」为前提，选项一暗置后同时获得此牌。此文件不挂载到任何武将。
local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jincai = fk.CreateSkill { name = "fengsui_heg__jincaiRemake3" }

jincai:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, _, target, player, data)
    return target and target == player and data and data.from and
      data.card and data.card.color == Card.Red and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = data.from == player and "#fengsui_heg__jincaiRemake3-invoke-self" or
        ("#fengsui_heg__jincaiRemake3-invoke::" .. data.from.id),
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local user = data.from
    local choices = { "fengsui_heg__jincaiRemake3_hide", "fengsui_heg__jincaiRemake3_obtain" }
    local choice = room:askToChoice(user, {
      choices = choices, skill_name = self.name,
      prompt = "#fengsui_heg__jincaiRemake3-choice::" .. player.id,
    })
    if choice == "fengsui_heg__jincaiRemake3_hide" then
      if not H.allGeneralsRevealed(user) then
        data:setNullified(player)
        return
      end
      local place = room:askToChoice(user, {
        choices = { "fengsui_heg__jincaiRemake3_main", "fengsui_heg__jincaiRemake3_deputy" },
        skill_name = self.name, prompt = "#fengsui_heg__jincaiRemake3-place",
      })
      user:hideGeneral(place == "fengsui_heg__jincaiRemake3_deputy")
      U.prohibitReveal(user, place == "fengsui_heg__jincaiRemake3_deputy", self.name, "turn")
    else
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, self.name)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__jincaiRemake3-invoke"] = "矜才：是否令 %dest 选择一项？",
  ["#fengsui_heg__jincaiRemake3-invoke-self"] = "矜才：是否发动？",
  ["fengsui_heg__jincaiRemake3_hide"] = "若你的武将牌均明置则暗置一张且本回合无法明置，否则此牌无效",
  ["fengsui_heg__jincaiRemake3_obtain"] = "令矜才拥有者获得此牌",
  ["fengsui_heg__jincaiRemake3_main"] = "暗置主将",
  ["fengsui_heg__jincaiRemake3_deputy"] = "暗置副将",
  ["#fengsui_heg__jincaiRemake3-place"] = "矜才：选择暗置的武将牌",
}

return jincai
