local H = require "packages.fengsui.hegemony_util"

local guixiang = fk.CreateSkill{
  name = "fengsui_heg__guixiang",
  tags = {Skill.Limited},
}

-- 提示词里的「当前为XX阶段」：沿用 on_use 里那四个选项的中文翻译。
local phaseNameKeys = {
  [Player.Judge] = "fengsui_heg__guixiang_judge",
  [Player.Draw] = "fengsui_heg__guixiang_draw",
  [Player.Play] = "fengsui_heg__guixiang_play",
  [Player.Discard] = "fengsui_heg__guixiang_discard",
}

guixiang:addEffect(fk.EventPhaseChanging, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(guixiang.name) or player.room.current ~= target or
      not H.compareKingdomWith(target, player) or
      player:usedSkillTimes(guixiang.name, Player.HistoryGame) > 0 then
      return false
    end
    if data.skipped or data.phase == Player.Start or data.phase == Player.Finish then return false end

    local same_count = 0
    for _, p in ipairs(player.room.alive_players) do
       if H.compareKingdomWith(p, player) then same_count = same_count + 1 end
    end

    local phase_count = target:getMark("fengsui_heg__guixiang_phase-turn") + 1
    target.room:setPlayerMark(target, "fengsui_heg__guixiang_phase-turn", phase_count)

    return phase_count == same_count
  end,
  on_cost = function(self, event, target, player, data)
    -- prompt 第 4 段才是 %arg；阶段名用橙黄色富文本，客户端按 RichText 渲染。
    local phaseKey = phaseNameKeys[data.phase]
    local phaseName = phaseKey and Fk:translate(phaseKey) or "未知阶段"
    return player.room:askToSkillInvoke(player, {
      skill_name = guixiang.name,
      prompt = "#fengsui_heg__guixiang-invoke::" .. target.id ..
        ":<font color='#FFA500'>" .. phaseName .. "</font>",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {
      "fengsui_heg__guixiang_judge",
      "fengsui_heg__guixiang_draw",
      "fengsui_heg__guixiang_play",
      "fengsui_heg__guixiang_discard",
    }
    local choice = room:askToChoice(player, {
      choices = choices,
      prompt = "#fengsui_heg__guixiang-choice",
      skill_name = guixiang.name,
    })

    local mapping = {
      fengsui_heg__guixiang_judge = Player.Judge,
      fengsui_heg__guixiang_draw = Player.Draw,
      fengsui_heg__guixiang_play = Player.Play,
      fengsui_heg__guixiang_discard = Player.Discard,
    }
    data.phase = mapping[choice]
    room:sendLog{
      type = "#fengsui_heg__guixiang-change",
      from = player.id,
      to = { target.id },
      arg = choice,
      toast = true,
    }
  end,
})

return guixiang
