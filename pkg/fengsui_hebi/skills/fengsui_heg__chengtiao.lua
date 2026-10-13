local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"
local chengtao = fk.CreateSkill { name = "fengsui_heg__chengtiao" }

local markLength = {
  vanguard = 2,
  yinyangfish = 3,
  companion = 4,
  wild = 3,
  fengsui_heg_ascend = 1,
  fengsui_heg__descend = 1,
}

chengtao:addEffect(H.HegMarkChanged, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return target and data and (data.number or 0) > 0 and
      player:hasShownSkill(self.name) and markLength[data.markName] ~= nil
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local count = markLength[data.markName] * math.max(1, data.number or 1)
    if #player:getCardIds("he") >= count then
      local num = count
      if num > 0 then
        local ids = room:askToChooseCards(player, {
          target = player,
          min = num,
          max = num,
          flag = "he",
          skill_name = self.name,
          prompt = "#fengsui_heg__chengtiao-recast",
        })
        if ids and #ids > 0 then room:recastCard(ids, player, self.name) end
      end
    end
    if data.markName == "companion" and player:getMark("fengsui_heg__chengtiao_changed") == 0 then
      room:setPlayerMark(player, "fengsui_heg__chengtiao_changed", 1)
      local place = U.getGeneralPlace(player, "fengsui_heg__hanmi")
      if place == nil then place = false end
      room:changeHero(player, "fengsui_heg__jiami", false, place, false, false, false)
      room:broadcastPlaySound("./packages/fengsui/audio/skill/fengsui_heg__chengtiao_change" .. math.random(2))
      local tos = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        skill_name = self.name,
        prompt = "#fengsui_heg__chengtiao-target",
      })
      local to = tos and tos[1]
      if to then
        local skill = room:askToChoice(player, {
          choices = {"fengsui_heg__menyin", "fengsui_heg__juesi"},
          skill_name = self.name, prompt = "#fengsui_heg__chengtiao-skill",
        })
        room:handleAddLoseSkills(to, skill)
      end
    end
  end,
})

return chengtao
