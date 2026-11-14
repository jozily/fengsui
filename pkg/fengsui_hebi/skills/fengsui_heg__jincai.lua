local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local jincai = fk.CreateSkill { name = "fengsui_heg__jincai" }

jincai:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, _, target, player, data)
    return target and target == player and data and data.from and
      data.card and data.card.color == Card.Red and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      H.allGeneralsRevealed(data.from) and
      player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = self.name,
      prompt = data.from == player and "#fengsui_heg__jincai-invoke-self" or
        ("#fengsui_heg__jincai-invoke::" .. data.from.id),
    })
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local user = data.from
    -- 使用者武将牌均明置是发动前提；若询问期间状态发生变化，退化为「此牌对你无效」
    if not H.allGeneralsRevealed(user) then
      data:setNullified(player)
      return
    end
    local choice = room:askToChoice(user, {
      choices = { "fengsui_heg__jincai_hide", "fengsui_heg__jincai_nullify" },
      skill_name = self.name,
      prompt = "#fengsui_heg__jincai-choice::" .. player.id,
    })
    if choice == "fengsui_heg__jincai_hide" then
      local place = room:askToChoice(user, {
        choices = { "fengsui_heg__jincai_main", "fengsui_heg__jincai_deputy" },
        skill_name = self.name, prompt = "#fengsui_heg__jincai-place",
      })
      user:hideGeneral(place == "fengsui_heg__jincai_deputy")
      U.prohibitReveal(user, place == "fengsui_heg__jincai_deputy", self.name, "turn")
      room:obtainCard(player, data.card, true, fk.ReasonPrey, player, self.name)
    else
      data:setNullified(player)
    end
  end,
})

Fk:loadTranslationTable{
  ["#fengsui_heg__jincai-invoke"] = "矜才：是否令 %dest 选择一项？",
  ["#fengsui_heg__jincai-invoke-self"] = "矜才：是否发动？",
  ["fengsui_heg__jincai_hide"] = "暗置一张武将牌且本回合无法明置，然后令矜才拥有者获得此牌",
  ["fengsui_heg__jincai_nullify"] = "令此牌对矜才拥有者无效",
  ["fengsui_heg__jincai_main"] = "暗置主将",
  ["fengsui_heg__jincai_deputy"] = "暗置副将",
  ["#fengsui_heg__jincai-place"] = "矜才：选择暗置的武将牌",
}

return jincai
