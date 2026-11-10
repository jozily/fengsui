local H = require "packages.fengsui.hegemony_util"
local Util = require "packages.utility.utility"

local linzhe = fk.CreateSkill{
  name = "fengsui_heg__linzhe",
  tags = { Skill.Limited },
}

local LINZHE_MARK = "fengsui_heg__linzhe_target"
local LINZHE_VISIBLE_MARK = "@fengsui_heg__linzhe_target"

linzhe:addEffect("active", {
  anim_type = "control",
  prompt = "#fengsui_heg__linzhe",
  can_use = function(self, player)
    return player:usedSkillTimes(linzhe.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      H.compareKingdomWith(player, to_select, true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    -- 隐藏标记与官方构逆一致，直接存目标对象供 compareKingdomWith 比较。
    room:addTableMarkIfNeed(player, LINZHE_MARK, target)
    -- 可见标记显示发动遴哲的主将名，便于辨认是谁标记的。
    room:setPlayerMark(target, LINZHE_VISIBLE_MARK,
      Fk:translate(H.getActualGeneral(player, false)))

    -- 视为同势力后，所有同势力角色（含山涛与被标记者）依次选择是否变更副将
    local targets = table.filter(room.alive_players, function(p)
      return H.compareKingdomWith(p, player)
    end)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if p:isAlive() and H.hasGeneral(p, true) then
        local choice = room:askToChoice(p, {
          choices = { "fengsui_heg__linzhe_transform", "Cancel" },
          skill_name = linzhe.name,
          prompt = "#fengsui_heg__linzhe-choice::" .. player.id,
        })
        if choice == "fengsui_heg__linzhe_transform" then
          H.transformGeneral(room, p, false, false)
        end
      end
    end
  end,
})

return linzhe
