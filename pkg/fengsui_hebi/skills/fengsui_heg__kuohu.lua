local H = require "packages.fengsui.hegemony_util"

local kuohu = fk.CreateSkill { name = "fengsui_heg__kuohu" }

local function chooseHideGeneral(room, target, skill_name)
  local places = {}
  if target.general ~= "anjiang" then table.insert(places, "fengsui_heg__kuohu_main") end
  if target.deputyGeneral ~= "anjiang" then table.insert(places, "fengsui_heg__kuohu_deputy") end
  if #places == 0 then return false end
  local choice = #places == 1 and places[1] or room:askToChoice(target, {
    choices = places, skill_name = skill_name, prompt = "#fengsui_heg__kuohu-place",
  })
  target:hideGeneral(choice == "fengsui_heg__kuohu_deputy")
  return true
end

kuohu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasShownSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mine = H.getGeneralsRevealedNum(player)
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return H.getGeneralsRevealedNum(p) <= mine
    end)
    if #targets == 0 then return false end
    local result = room:askToChoosePlayers(player, {
      targets = targets, min_num = 1, max_num = 1, skill_name = self.name,
      prompt = "#fengsui_heg__kuohu-target", cancelable = true,
    })
    if result and #result > 0 then
      self.cost_data = result[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data
    if not to or not to:isAlive() then return end
    local choices = {}
    local canReveal = (to.general == "anjiang" and not to:prohibitReveal()) or
      (to.deputyGeneral == "anjiang" and not to:prohibitReveal(true))
    if canReveal then table.insert(choices, "fengsui_heg__kuohu_reveal") end
    if H.getGeneralsRevealedNum(to) > 0 then table.insert(choices, "fengsui_heg__kuohu_hide") end
    if #choices == 0 then return end
    local choice = #choices == 1 and choices[1] or room:askToChoice(to, {
      choices = choices, skill_name = self.name, prompt = "#fengsui_heg__kuohu-choice",
    })
    if choice == "fengsui_heg__kuohu_reveal" then
      H.askToRevealGenerals(to, { skill_name = self.name, revealAll = false, cancelable = false })
      if to:isAlive() then to:drawCards(1, self.name) end
    else
      chooseHideGeneral(room, to, self.name)
    end
  end,
})

return kuohu
