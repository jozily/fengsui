local H = require "packages.fengsui.hegemony_util"

local jietu = fk.CreateSkill{
  name = "fengsui_heg__jietuRemake",
}
jietu:addEffect("active", {
  anim_type = "support",
  prompt = "#fengsui_heg__jietuRemake-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jietu.name, Player.HistoryPhase) == 0 and
      H.inFormationRelation(player, player)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local formation = table.simpleClone(H.getFormationRelation(player))
    table.insert(formation, player)
    room:sortByAction(formation)

    for _, p in ipairs(formation) do
       if not p:isNude() and p:isAlive() then
          local cid = room:askToChooseCard(p, {
             target = p,
             flag = "he",
             skill_name = jietu.name,
             prompt = "#fengsui_heg__jietuRemake-recast",
          })
          if cid then
             local cobj = Fk:getCardById(cid)
             local isEquip = cobj.type == Card.TypeEquip
             room:recastCard(cid, p, jietu.name)
             if isEquip and p:isAlive() then
                p:drawCards(1, jietu.name)
                room:addPlayerMark(p, "fengsui_heg__jietuRemake_slash_bonus-round", 1)
             end
          end
       end
    end
  end,
})

jietu:addEffect("targetmod", {
  global = true,
  residue_func = function(self, player, skill, scope)
    -- 此轮内
    local total = player:getMark("fengsui_heg__jietuRemake_slash_bonus-round")
    if total > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return total
    end
  end,
})
Fk:loadTranslationTable{
  ["fengsui_heg__jietuRemake"] = "捷途",
  [":fengsui_heg__jietuRemake"] = "阵法技，出牌阶段限一次，你可以重铸与你同一队列所有角色的各一张牌。与你同一队列的角色重铸牌后，若为装备牌，则其摸一张牌且本轮于出牌阶段内使用【杀】次数+1。",
  ["#fengsui_heg__jietuRemake-active"] = "捷途：令同一队列所有角色各重铸一张牌",
  ["#fengsui_heg__jietuRemake-recast"] = "捷途：请选择一张牌进行重铸。若你重铸了装备牌将额外摸牌并增加出【杀】次数",
}

return jietu
