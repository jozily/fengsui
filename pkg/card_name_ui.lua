local M = {}

function M.create(skillName, choices, allChoices)
  if type(choices) ~= "table" or #choices == 0 then return end

  return UI.CardNameBox {
    choices = choices,
    all_choices = allChoices or choices,
  }
end

return M
