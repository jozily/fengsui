local M = {}

function M.create(skillName, choices, allChoices, default)
  if type(choices) ~= "table" or #choices == 0 then return end

  return UI.CardNameBox {
    choices = choices,
    all_choices = allChoices or choices,
    default = default,
  }
end

return M
