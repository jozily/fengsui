local H = require "packages.fengsui.hegemony_util"
local U = require "packages.fengsui.pkg.fengsui_hebi.util"

local linzhe = fk.CreateSkill{
  name = "fengsui_heg__linzhe",
}

linzhe:addEffect("active", {
  prompt = "#fengsui_heg__linzhe",
  can_use = function(self, player)
    return player:usedSkillTimes(linzhe.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    room:sortByAction(targets)

    for _, p in ipairs(targets) do
      if p:isAlive() then
        local tricks = table.filter(p:getCardIds("h"), function(id)
          local card = Fk:getCardById(id)
          return card.type == Card.TypeTrick and
            (#card:getAvailableTargets(p, {bypass_distances = true}) > 0 or card.is_passive)
        end)
        local choices = {"fengsui_heg__linzhe_mark"}
        if #tricks > 0 and H.hasGeneral(p, true) then
          table.insert(choices, 1, "fengsui_heg__linzhe_trick_transform")
        end
        local choice = room:askToChoice(p, {
          choices = choices,
          prompt = "#fengsui_heg__linzhe-choice",
          skill_name = linzhe.name,
        })
        if choice == "fengsui_heg__linzhe_trick_transform" then
          room:askToUseRealCard(p, {
            pattern = tricks,
            prompt = "#fengsui_heg__linzhe-trick",
            skill_name = linzhe.name,
            cancelable = false,
            extra_data = {bypass_distances = true},
          })
          H.transformGeneral(room, p, false, false)
        else
          if p:getHandcardNum() == p.maxHp then
            H.addHegMark(p, "companion")
          else
            H.addHegMark(p, "yinyangfish")
          end
        end
      end
    end
    if player:isAlive() and not H.isBigKingdomPlayer(player) then
      room:handleAddLoseSkills(player, "-" .. linzhe.name)
    end
  end,
})

return linzhe
