local H = require "packages.fengsui.hegemony_util"

local hejue = fk.CreateSkill{
  name = "fengsui_heg__hejueRemake",
}

local function handleHejue(room, player)
   local all_gens = {}
   for _, p in ipairs(room.alive_players) do
      if p.general ~= "anjiang" and not p.general:startsWith("blank_") then table.insert(all_gens, p.general) end
      if p.deputyGeneral ~= "anjiang" and not p.deputyGeneral:startsWith("blank_") then table.insert(all_gens, p.deputyGeneral) end
   end
   if #all_gens == 0 then return end

   local U = require "packages.utility.utility"
   local choices = U.askToChooseGeneralsAndChoice(player, {
      skill_name = hejue.name,
      generals = all_gens,
      prompt = "#fengsui_heg__hejueRemake-choose",
      min_num = 1,
      max_num = 2,
   })
   if #choices > 0 then
      if #choices == 2 then
         local first, second = Fk.generals[choices[1]], Fk.generals[choices[2]]
         local is_comp = first and second and first:isCompanionWith(second)
         if is_comp then
            for _, gen in ipairs(choices) do
               for _, p in ipairs(room.alive_players) do
                  if p.general == gen or p.deputyGeneral == gen then p:drawCards(1, hejue.name) end
               end
            end
         end
      elseif #choices == 1 then
         for _, p in ipairs(room.alive_players) do
            if p.general == choices[1] or p.deputyGeneral == choices[1] then
               local op = room:askToChoice(player, {
                  choices = {"fengsui_heg__hejueRemake_hebi", "fengsui_heg__hejueRemake_transform", "Cancel"},
                  skill_name = hejue.name,
                  prompt = "#fengsui_heg__hejueRemake-choice"
               })
               if op == "fengsui_heg__hejueRemake_hebi" then
                  H.askToHebiOrTransform(room, p, hejue.name, false)
               elseif op == "fengsui_heg__hejueRemake_transform" then
                  H.transformGeneral(room, p, false, false)
               end
               break
            end
         end
      end
   end
end

hejue:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hejue.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = hejue.name, prompt = "#fengsui_heg__hejueRemake-invoke1" })
  end,
  on_use = function(self, event, target, player, data)
    handleHejue(player.room, player)
  end,
})

hejue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:hasSkill(hejue.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = hejue.name, prompt = "#fengsui_heg__hejueRemake-invoke2" })
  end,
  on_use = function(self, event, target, player, data)
    handleHejue(player.room, player)
  end,
})

Fk:loadTranslationTable{
 ["#fengsui_heg__hejueRemake-invoke1"] = "合珏：是否发动？",
  ["#fengsui_heg__hejueRemake-invoke2"] = "合珏：结束阶段是否发动？",
  ["#fengsui_heg__hejueRemake-choose"] = "合珏：选择一张或两张武将牌对应的角色",
  ["#fengsui_heg__hejueRemake-choice"] = "合珏：请选择一种方式影响该角色",
  ["fengsui_heg__hejueRemake_hebi"] = "令其合璧",
  ["fengsui_heg__hejueRemake_transform"] = "令其变更副将",
}

return hejue
