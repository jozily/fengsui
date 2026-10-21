local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local kuohu = fk.CreateSkill { name = "fengsui_heg__kuohu" }
local disabledMark = "fengsui_heg__kuohu_disabled-round"

kuohu:addEffect("active", {
  anim_type = "control", card_num = 0, target_num = 1,
  can_use = function(self, player)
    return player.phase == Player.Play and player:hasShownSkill(self.name) and
      player:getMark(disabledMark) == 0 and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = U.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select:isAlive() and
      player:inMyAttackRange(to_select)
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    local shown = H.getGeneralsRevealedNum(target)
    local choices = {}
    if shown == 2 then
      if target.general ~= "anjiang" then table.insert(choices, "fengsui_heg__kuohu_main") end
      if target.deputyGeneral ~= "anjiang" then table.insert(choices, "fengsui_heg__kuohu_deputy") end
    elseif target.general == "anjiang" or target.deputyGeneral == "anjiang" then
      table.insert(choices, "fengsui_heg__kuohu_reveal")
    end
    if #choices == 0 then
      local ids = target:getCardIds("he")
      if #ids > 0 then
        local id = room:askToChooseCard(player, { target = target, flag = "he", skill_name = self.name,
          prompt = "#fengsui_heg__kuohu-gain::" .. target.id })
        if id then room:obtainCard(player, id, true, fk.ReasonPrey, player, self.name) end
      end
      room:drawCards(target, 1, self.name)
      if not H.compareKingdomWith(player, target) then room:setPlayerMark(player, disabledMark, 1) end
      return
    end
    local choice = #choices == 1 and choices[1] or room:askToChoice(target, {
      choices = choices, skill_name = self.name, prompt = "#fengsui_heg__kuohu-choice",
    })
    if choice == "fengsui_heg__kuohu_reveal" then
      if target.general == "anjiang" then target:revealGeneral(false)
      elseif target.deputyGeneral == "anjiang" then target:revealGeneral(true) end
    else
      target:hideGeneral(choice == "fengsui_heg__kuohu_deputy")
    end
    room:drawCards(target, 1, self.name)
    if not H.compareKingdomWith(player, target) then room:setPlayerMark(player, disabledMark, 1) end
  end,
})

kuohu:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from and from:getMark(disabledMark) > 0 and skill.name == kuohu.name
  end,
})

return kuohu
