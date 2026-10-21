local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local xiarong = fk.CreateSkill {name = "fengsui_heg__xiarong"}
xiarong:addEffect(fk.Damaged, {
  global = true,
  can_trigger = function(self, _, target, player)
    return player:hasSkill(self.name) and target and H.compareKingdomWith(player, target) and
      H.allGeneralsRevealed(player) and H.allGeneralsRevealed(target)
  end,
  on_cost = function(self, _, target, player)
    return player.room:askToSkillInvoke(player, {skill_name = self.name, prompt = "#fengsui_heg__xiarong-invoke::" .. target.id})
  end,
  on_use = function(self, _, target, player)
    local room = player.room
    local place = U.getSkillPlace(player, self.name)
    if target ~= player then
      place = room:askToChoice(player, {choices = {"mainGeneral", "deputyGeneral"}, skill_name = self.name}) == "deputyGeneral"
    end
    if place == nil then return end
    player:hideGeneral(place)
    if target ~= player and target:isAlive() then
      local choice = room:askToChoice(target, {choices = {"mainGeneral", "deputyGeneral"}, skill_name = self.name})
      target:hideGeneral(choice == "deputyGeneral")
    end
    if target:isAlive() then room:recover{who = target, num = 1, recoverBy = player, skillName = self.name} end
  end,
})
return xiarong
