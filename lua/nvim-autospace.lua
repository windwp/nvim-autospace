local M = {}

local char_rule ={
    ["+"] = {
      before = {prev = "[%w'\"%]%)]", next="."},
      after  = {prev = ".", next = "[%w'\"%(]"}
    },
    ["-"] = {
      before = {prev = "[%w'\"%]%)]", next="[%w]"},
      after  = {prev = "[%w%(%] ]", next = "[a-zA-Z'\"%(]"}
    },
    ["="] = {
      before = {prev = "[%w'\"%]%)]", next = "[ =%w%{\"\']"},
      after  = {prev = ".", next = "[%w'\"%(%{]"}
    },
    [">"]={
      before = {prev = "[%w'\"%]%)]", next = "[ =%w%{\"\']"},
      after  = {prev = ".", next = "[%w'\"%(%{]"}
    },
    ["<"]={
      before = {prev = "[%w'\"%]%)]", next = "[ =%w%{\"\']"},
      after  = {prev = ".", next = "[%w'\"%(%{]"}
    },
    ["&"] = {
      before = {prev = "[%w'\"%]%)]", next="."},
      after  = {prev = ".", next = "[%w'\"%(]"}
    },
    [")"] = {
      after  = {prev = ".", next = "[%w]"}
    },
    [":"] = {
      after  = {prev = ".", next = "[%w'\"%(]", disable_ft = {'lua', 'vim'}}
    },
    ["!"] = {
      before = {prev = "[%w'\"%)]", next = "="},
    },
    ["~"] = {
      before = {prev = "[%w'\"%)]", next = "=", ft = {'lua'}},
    },
    ["."]={
      after  = {prev = "%.", next = "[%w'\"%(]" , ft = { "lua" }},
      before = {prev = "[%w'\"%]%)]", next = "%." , ft = { "lua" }}
    },
    [","]={
      after  = {prev = ".", next = "[%w'\"%(]" ,},
    },
}

local enable_filetypes = {'lua', 'javascript', 'typescript', 'typescriptreact', 'go', 'java', 'csharp', 'vim', 'python'}

local function isNotInTable(tbl, val)
  if tbl == nil then return true end
  for _, value in pairs(tbl) do
    if value == val then return false end
  end
  return true
end

local function isInTable(tbl, val)
  if tbl == nil then return true end
  for _, value in pairs(tbl) do
    if value == val then return true end
  end
  return false
end
local function getNotEmptychar(text, pos, direction)
  local charIndex = pos
  while charIndex < string.len(text)  and charIndex >= 0 do
    charIndex = charIndex + direction
    local char = text:sub(charIndex, charIndex)
    if char ~= " "  then return {char, charIndex} end
  end
  return nil
end

M.setup = function(opts)
  opts.enable_filetypes = opts.enable_filetypes or enable_filetypes
  if opts.rule ~= nil then
    for key, r in pairs(opts.rule) do
      char_rule[key]= r
    end
  end
end


local function is_in_quote(line, pos)
  local cIndex = 0
  local last_quote = ''
  local result = false
  while cIndex < string.len(line) and cIndex < pos  do
    cIndex = cIndex + 1
    local char = line:sub(cIndex, cIndex)
    if
      result == true and
      char == last_quote and
      line:sub(cIndex -1, cIndex -1) ~= "\\"
    then
       result = false
     elseif result == false and (char == "'" or char == '"') then
        last_quote = char
        result = true
    end
  end
  return result
end

M.format = function(lineSkip)
  local pos       = vim.fn.getpos('.')
  local line      = vim.fn.getline('.')
  local charIndex = 0
  -- special case check cursor is end of line
  if lineSkip == 999 then
    if pos[3] <= (string.len(line) - 1) then return else lineSkip = 0 end
  end
  local lnr = pos[2]
  if lineSkip ~= nil then
    lnr = lnr + lineSkip
  end
  line = vim.fn.getline(lnr)

  if lineSkip ~= nil and isNotInTable(enable_filetypes, vim.bo.filetype) == true then return end

  while charIndex < string.len(line) do
    charIndex = charIndex + 1
    local char      = line:sub(charIndex, charIndex)
    local pre_char  = line:sub(charIndex - 1, charIndex - 1)
    local next_char = line:sub(charIndex + 1, charIndex + 1)
    local isInQuote = is_in_quote(line, charIndex )
    if isInQuote == false then
      local rule = char_rule[char]
      if rule ~= nil then
        if
          rule.before ~= nil and
          isNotInTable(rule.before.disable_ft, vim.bo.filetype) == true and
          isInTable(rule.before.ft, vim.bo.filetype) == true and
          string.match(pre_char, rule.before.prev) and
          string.match(next_char, rule.before.next)
        then
           line = line:sub(0, charIndex - 1).." ".. char .. line:sub(charIndex + 1, string.len(line))
           charIndex = charIndex + 1
        end
        if
          rule.after ~= nil and
          isNotInTable(rule.after.disable_ft, vim.bo.filetype) == true and
          isInTable(rule.after.ft, vim.bo.filetype) == true and
          string.match(pre_char, rule.after.prev) and
          string.match(next_char, rule.after.next)
        then
           line = line:sub(0, charIndex -1).. char .. " " .. line:sub(charIndex + 1, string.len(line))
        end
      end

      if char == " " then
        local prev_obj = getNotEmptychar(line, charIndex,-1)
        local next_obj = getNotEmptychar(line, charIndex, 1)
        if prev_obj ~= nil and next_obj ~= nil then
          if
            next_obj[2] - prev_obj[2] > 2 and
            string.match(prev_obj[1], "[%w\"%)%],]") and
            string.match(next_obj[1], "[%w\"%)%]%.]")
          then
            line = line:sub(0, prev_obj[2]) .. ' ' .. line:sub(next_obj[2], string.len(line))
            charIndex = charIndex -(next_obj[2]-prev_obj[2]) -2
          end
          -- remove empty (abc   ,aa) => (abc, aa)
          if
            next_obj[2] - prev_obj[2] > 1 and
            next_obj[1] == "," and
            string.match(prev_obj[1], "[%w\"]")
          then
            line = line:sub(0, prev_obj[2]) .. line:sub(next_obj[2], string.len(line))
            charIndex = charIndex - (next_obj[2] - prev_obj[2]) -2
          end

        end
      end
    end
  end

  vim.fn.setline(lnr, line)
end

M.is_in_quote = is_in_quote
return M
