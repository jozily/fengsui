local H = require "packages.fengsui.hegemony_util"

local yinxian = fk.CreateSkill{name = "fengsui_limited_heg__yinxian"}

Fk:loadTranslationTable{
  ["fengsui_limited_heg__yinxian"] = "引线",
  [":fengsui_limited_heg__yinxian"] = "出牌阶段限一次，你可以选择一名角色并进行判定，若判定结果不小于X，令其使用一张【火烧连营】；否则，你可以视为使用一张不计入次数的火【杀】（X为该角色势力角色已明置武将牌数）。",
  ["#fengsui_limited_heg__yinxian"] = "引线：选择一名角色并判定",
  ["#fengsui_limited_heg__yinxian-slash"] = "引线：你可以视为使用一张不计入次数的火【杀】",
  ["@fengsui_limited_heg__yinxian"] = "引线",
}

local function shownKingdomGenerals(target)
  local n = 0
  for _, p in ipairs(target.room.alive_players) do
    if H.compareKingdomWith(target, p) then n = n + H.getGeneralsRevealedNum(p) end
  end
  return n
end

local function useBurningCamps(player)
  if player:isAlive() and player:canUse(Fk:cloneCard("burning_camps"), { bypass_times = true }) then
    player.room:useVirtualCard("burning_camps", nil, player, nil, yinxian.name, true,
      { bypass_times = true, extraUse = true })
  end
end

yinxian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#fengsui_limited_heg__yinxian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yinxian.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player, target = effect.from, effect.tos[1]
    local x = shownKingdomGenerals(target)
    local judge = { who = player, reason = yinxian.name, pattern = "." }
    room:judge(judge)
    if judge.card and judge.card.number >= x then
      useBurningCamps(target)
    elseif player:isAlive() then
      room:askToUseVirtualCard(player, {
        name = "fire__slash",
        skill_name = yinxian.name,
        prompt = "#fengsui_limited_heg__yinxian-slash",
        cancelable = true,
        extra_data = { bypass_times = true, extraUse = true },
      })
    end
  end,
})

return yinxian
