local H = require "packages.fengsui.hegemony_util"

local hejue = fk.CreateSkill{
  name = "fengsui_heg__hejue",
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
      prompt = "#fengsui_heg__hejue-choose",
      min_num = 1,
      max_num = 2,
   })
   if #choices > 0 then
      local owners = {}
      for _, gen in ipairs(choices) do
         local owner = table.find(room.alive_players, function(p)
            return p.general == gen or p.deputyGeneral == gen
         end)
         if owner then table.insertIfNeed(owners, owner) end
      end
      if #choices == 2 then
         local first, second = Fk.generals[choices[1]], Fk.generals[choices[2]]
         local is_comp = first and second and first:isCompanionWith(second)
         if is_comp then
            for _, gen in ipairs(choices) do
               local owner = table.find(room.alive_players, function(p)
                  return p.general == gen or p.deputyGeneral == gen
               end)
               if owner and owner:isAlive() then
                  owner:drawCards(1, hejue.name)
               end
            end
         end
      end
      if #owners == 1 and owners[1]:isAlive() then
         H.askToHebiOrTransform(room, owners[1], hejue.name, true)
      end
   end
end

hejue:addEffect(fk.Damaged, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hejue.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = hejue.name, prompt = "#fengsui_heg__hejue-invoke1" })
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
    return player.room:askToSkillInvoke(player, { skill_name = hejue.name, prompt = "#fengsui_heg__hejue-invoke2" })
  end,
  on_use = function(self, event, target, player, data)
    handleHejue(player.room, player)
  end,
})

Fk:loadTranslationTable{
 ["#fengsui_heg__hejue-invoke1"] = "合珏：是否发动？",
  ["#fengsui_heg__hejue-invoke2"] = "合珏：结束阶段是否发动？",
  ["#fengsui_heg__hejue-choose"] = "合珏：选择一张或两张武将牌对应的角色",
}

return hejue
