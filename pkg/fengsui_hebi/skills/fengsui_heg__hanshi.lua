-- 酣世：限定技，回合结束时，你可令一名同势力角色进行一个额外的回合，
-- 此回合内所有角色获得「矢北」。
--
-- 实现要点（改之前务必先读）：
--   ① 引擎的判断顺序是先看「这个效果技此刻能不能发动」，再看要不要问。没写 can_trigger 的
--      效果技，用的是 TriggerSkill:triggerable 的默认实现：
--          return target and (target == player) and (self.global or target:hasSkill(...))
--      也就是说 global 效果永远「可以发动」，不管技能属于谁、时机对不对。而触发循环里
--      只要同一优先级有两个以上可发动技，就会真的弹一个「选择要发动的技能」选框
--      （trigger_event.lua:158 的 askToChoice，单选项才会自动跳过）。所以本文件两条效果
--      都写了 can_trigger，把「可发动」收窄到真正该干事的那一刻；否则会在每次回合开始时
--      给全场弹一个写着「酣世」的选框，与是否有人选梦周宣毫无关系。
--   ② 两条效果必须分在不同优先级：TurnStart 这条用 2，仙气模块用 3。同优先级会合并成
--      一个选框，看起来就像「酣世在回合开始问要不要发动」。
--   ③ 第二条效果走 on_trigger 而不是 on_use：它只是把矢北发下去，不该产生技能效果，
--      免得界面上多一条「发动酣世」的记录、还多播一句语音。
--   ④ gainAnExtraTurn 第一个参数 true 表示排队：额外回合插进 room.extra_turn_list 队首，
--      等当前回合的收尾流程跑完再开始，因此从 TurnEnd 里调用是安全的。
local H = require "packages.fengsui.hegemony_util"

local hanshi = fk.CreateSkill {
  name = "fengsui_heg__hanshi",
  tags = { Skill.Limited },
  -- 矢北由本技能在额外回合内临时发给全场，不是梦周宣的常驻技能。
  -- 登记为相关技能，只为让梦周宣的武将详情页列出矢北及其四条语音/台词；
  -- 骨架层的 related_skills 不参与 Player:addSkill 的级联，不会让梦周宣常驻获得矢北。
  related_skills = { "fengsui_heg__shibei" },
}

-- 排队中的额外回合；额外回合开始后置 0
local pendingMark = "fengsui_heg__hanshi_pending"
-- 处于「所有角色拥有矢北」的额外回合中
local activeMark = "fengsui_heg__hanshi_shibei"

local function kingdomTargets(player)
  return table.filter(player.room.alive_players, function(p)
    return H.compareKingdomWith(player, p)
  end)
end

-- 自己的回合结束时发动，令一名同势力角色获得一个额外回合
hanshi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, _, target, player, data)
    return target == player and player:isAlive() and player:hasSkill(hanshi.name) and
      player:usedSkillTimes(hanshi.name, Player.HistoryGame) == 0 and
      data and data.reason == "game_rule" and #kingdomTargets(player) > 0
  end,
  on_cost = function(self, _, _, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = hanshi.name,
      prompt = "#fengsui_heg__hanshi-invoke",
    })
  end,
  on_use = function(self, _, _, player)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = kingdomTargets(player),
      min_num = 1,
      max_num = 1,
      cancelable = false,
      prompt = "#fengsui_heg__hanshi-target",
      skill_name = hanshi.name,
    })[1]
    if not to then return end
    room:setPlayerMark(to, pendingMark, 1)
    to:gainAnExtraTurn(true, hanshi.name)
  end,
})

-- 该额外回合开始时，所有角色获得矢北。
-- can_trigger 只认「回合原因 = 酣世」且本回合确有待发的矢北，平时一律不可发动，
-- 因此不会出现在任何「选择要发动的技能」选框里。
hanshi:addEffect(fk.TurnStart, {
  global = true,
  priority = 2,   -- 抢在其他「回合开始」效果之前把矢北发下去；仙气模块用 3，别撞
  can_trigger = function(self, _, target, player, data)
    return target ~= nil and target == player and target:isAlive()
      and data ~= nil and data.reason == hanshi.name
      and target:getMark(pendingMark) > 0
  end,
  on_trigger = function(self, _, target)
    local room = target.room
    if target:getMark(pendingMark) <= 0 then return end
    room:setPlayerMark(target, pendingMark, 0)
    room:setPlayerMark(target, activeMark, 1)
    for _, p in ipairs(room.alive_players) do
      room:handleAddLoseSkills(p, "fengsui_heg__shibei")
    end
  end,
})

-- 该回合结束，收回所有角色的矢北
-- 收尾由矢北自身承担（见 fengsui_heg__shibei.lua），这样即使梦周宣阵亡也能正常收回。

return hanshi
