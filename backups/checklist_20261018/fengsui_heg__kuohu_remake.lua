local Util = require "packages.fengsui.pkg.fengsui_hebi.util"
local kuohu = fk.CreateSkill { name = "fengsui_heg__kuohu" }
kuohu:addEffect("active", {
  anim_type = "control", card_num = 0, target_num = 1,
  can_use = function(self, player)
    return player.phase == Player.Play and Util.hasGeneralName(player, "fengsui_heg__shanxia") and player:hasShownSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local forced = player:getMark("fengsui_heg__kuohu_forced_target")
    return #selected == 0 and to_select ~= player and to_select:isAlive() and player:inMyAttackRange(to_select) and (forced == 0 or forced == to_select.id)
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    local choices = { "fengsui_heg__kuohu_draw" }
    if target.general ~= "anjiang" and target.deputyGeneral ~= "anjiang" then table.insert(choices, "fengsui_heg__kuohu_hide") end
    if target.general == "anjiang" or target.deputyGeneral == "anjiang" then table.insert(choices, "fengsui_heg__kuohu_reveal") end
    local choice = room:askToChoice(target, { choices = choices, skill_name = self.name })
    if choice == "fengsui_heg__kuohu_draw" then
      room:drawCards(effect.from, 2, self.name)
      room:setPlayerMark(effect.from, "fengsui_heg__kuohu_unlimited", target.id)
    elseif choice == "fengsui_heg__kuohu_reveal" then
      if target.general == "anjiang" then target:revealGeneral(false) elseif target.deputyGeneral == "anjiang" then target:revealGeneral(true) end
      local ids = target:getCardIds("hej")
      if #ids > 0 then room:obtainCard(effect.from, ids[1], true, fk.ReasonPrey, effect.from, self.name) end
    else
      local places = {}
      if target.general ~= "anjiang" then table.insert(places, "fengsui_heg__kuohu_main") end
      if target.deputyGeneral ~= "anjiang" then table.insert(places, "fengsui_heg__kuohu_deputy") end
      local place = #places == 1 and places[1] or room:askToChoice(target, { choices = places, skill_name = self.name })
      target:hideGeneral(place == "fengsui_heg__kuohu_deputy")
      room:setPlayerMark(target, "fengsui_heg__kuohu_hidden-turn", 1)
      local slot = place == "fengsui_heg__kuohu_deputy" and "d" or "m"
      room:setPlayerMark(target, "fengsui_heg__kuohu_hidden_slot-turn", slot)
      Util.prohibitReveal(target, slot == "d", self.name, "turn")
      room:drawCards(target, 1, self.name)
    end
  end,
})
kuohu:addEffect(fk.GeneralRevealed, { global = true,
  can_refresh = function(self, _, target) return target and target:getMark("fengsui_heg__kuohu_hidden-turn") > 0 end,
  on_refresh = function(self, _, target, player, data)
    local slot = target:getMark("fengsui_heg__kuohu_hidden_slot-turn")
    if data and data.m and slot == "m" and target.general ~= "anjiang" then target:hideGeneral(false) end
    if data and data.d and slot == "d" and target.deputyGeneral ~= "anjiang" then target:hideGeneral(true) end
  end,
})
kuohu:addEffect(fk.CardUsing, { global = true,
  can_trigger = function(self, _, target, player, data)
    local id = player:getMark("fengsui_heg__kuohu_unlimited")
    return target == player and id > 0 and data and data.tos and table.find(data.tos, function(p) return p.id == id end) ~= nil
  end,
  on_use = function(self, _, _, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.bypass_times = true
  end,
})
kuohu:addEffect(fk.TurnEnd, { global = true,
  can_refresh = function(self, _, target) return target and target:getMark("fengsui_heg__kuohu_unlimited") > 0 end,
  on_refresh = function(self, _, target) target.room:setPlayerMark(target, "fengsui_heg__kuohu_unlimited", 0) end,
})
kuohu:addEffect(fk.TurnStart, { global = true, is_delay_effect = true,
  can_trigger = function(self, _, target) return target and target:getMark("fengsui_heg__kuohu_hidden-turn") > 0 end,
  on_use = function(self, _, target)
    target.room:setPlayerMark(target, "fengsui_heg__kuohu_hidden-turn", 0)
    target.room:setPlayerMark(target, "fengsui_heg__kuohu_hidden_slot-turn", 0)
  end,
})
return kuohu