local H = require "packages.fengsui.hegemony_util"
local M = {}
_G.__fengsui_heg_daoli_stolen = _G.__fengsui_heg_daoli_stolen or {}
_G.__fengsui_heg_daoli_pending = _G.__fengsui_heg_daoli_pending or {}
_G.__fengsui_heg_daoli_marks = _G.__fengsui_heg_daoli_marks or {}

M.marks = {
  "yinyangfish", "vanguard", "companion", "wild",
  "fengsui_heg_ascend", "fengsui_heg__descend",
}

function M.prepare(room, receiver, deceased)
  local skills = {}
  for _, deputy in ipairs({false, true}) do
    local general = Fk.generals[H.getActualGeneral(deceased, deputy)]
    if general then
      for _, name in ipairs(general:getSkillNameList(true)) do
        local skill = Fk.skills[name]
        if skill and not receiver:hasSkill(name, true, true) and
          not (skill:hasTag(Skill.Limited) and deceased:usedSkillTimes(name, Player.HistoryGame) > 0) then
          table.insertIfNeed(skills, name)
        end
      end
    end
  end
  local cards = deceased:getCardIds("hej")
  if #cards > 0 then
    room:obtainCard(receiver, cards, true, fk.ReasonPrey, deceased, "fengsui_heg__daoli")
  end
  local gained = {}
  for _, mark in ipairs(M.marks) do
    local count = deceased:getMark("@!!" .. mark)
    if count > 0 then
      H.addHegMark(receiver, mark, count)
      H.removeHegMark(room, deceased, mark, count)
      gained[mark] = count
    end
  end
  _G.__fengsui_heg_daoli_stolen[receiver.id] = cards
  _G.__fengsui_heg_daoli_pending[receiver.id] = skills
  _G.__fengsui_heg_daoli_marks[receiver.id] = gained
  room:setPlayerMark(receiver, "fengsui_heg__daoli_extra", 1)
end

return M
