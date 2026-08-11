local H = require "packages.fengsui.hegemony_util"

local ruwu = fk.CreateSkill{
  name = "fengsui_heg__ruwu",
  tags = { Skill.DeputyPlace, Skill.Compulsory },
}

local mark_skills = {
  ["vanguard_skill&"] = 1,
  ["yinyangfish_skill&"] = 1,
  ["companion_draw&"] = 2,
  ["wild_draw&"] = 1,
}

local function resolveRuwu(player, target, skill_name)
    local room = player.room
    player:drawCards(mark_skills[skill_name], ruwu.name)
    if player.dead or H.compareKingdomWith(target, player) then return end

    local x = #table.filter(room.alive_players, function(p)
      return p:getMark("@!!companion") > 0 or p:getMark("@!!yinyangfish") > 0 or
        p:getMark("@!!vanguard") > 0 or p:getMark("@!!wild") > 0
    end)
    local choices = {"fengsui_heg__ruwu_transform"}
    if #player:getCardIds("he") >= x then
      table.insert(choices, 1, "fengsui_heg__ruwu_yinyang")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = ruwu.name,
      prompt = "#fengsui_heg__ruwu-choice",
    })
    if choice == "fengsui_heg__ruwu_yinyang" then
      if x > 0 then
        local cards = room:askToDiscard(player, {
          min_num = x,
          max_num = x,
          include_equip = true,
          skill_name = ruwu.name,
          prompt = "#fengsui_heg__ruwu-drop:::" .. x,
          cancelable = false,
        })
        if #cards ~= x or player.dead then return end
      end
      H.addHegMark(player, "yinyangfish")
    else
      H.transformGeneral(room, player, false, false)
    end
end

ruwu:addEffect(fk.EventAcquireSkill, {
  global = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(ruwu.name) and data.skill and
      mark_skills[data.skill.name] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    resolveRuwu(player, target, data.skill.name)
  end,
})

ruwu:addEffect(fk.AfterSkillEffect, {
  global = true,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(ruwu.name) and data.skill and
      mark_skills[data.skill.name] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    resolveRuwu(player, target, data.skill.name)
  end,
})

return ruwu
