local M = {}

local char_rule ={
    ["+"] = {
      before = {prev = "[a-zA-Z0-9'\"%]%)]", next="."},
      after  = {prev = ".", next = "[a-zA-Z0-9'\"%(]"}
    },
    ["-"] = {
      before = {prev = "[a-zA-Z0-9'\"%)]", next="[0-9]"},
      after  = {prev = "[\\(]", next = "[a-zA-Z0-9'\"%(]"}
    },
    ["="] = {
      before = {prev = "[a-zA-Z0-9'\"%]%)]", next = "[ =0-9%w%{\"\']"},
      after  = {prev = ".", next = "[a-zA-Z0-9'\"%(%{]"}
    },
    ["&"] = {
      before = {prev = "[a-zA-Z0-9'\"%]%)]", next="."},
      after  = {prev = ".", next = "[a-zA-Z0-9'\"%(]"}
    },
    [")"] = {
      after  = {prev = ".", next = "[a-zA-Z0-9]"}
    },
    [":"] = {
      after  = {prev = ".", next = "[a-zA-Z0-9'\"%(]", disable_ft = {'lua', 'vim'}}
    },
    ["!"] = {
      before = {prev = "[a-zA-Z0-9'\"%)]", next = "="},
    },
    ["~"] = {
      before = {prev = "[a-zA-Z0-9'\"%)]", next = "=", ft = {'lua'}},
    },
    ["."]={
      after  = {prev = "%.", next = "[a-zA-Z0-9'\"%(]" , ft = { "lua" }},
      before = {prev = "[a-zA-Z0-9'\"%]%)]", next = "%." , ft = { "lua" }}
    },
    [","]={
      after = {prev = ".", next = "[a-zA-Z0-9'\"%(]" ,},
    }
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

M.setup = function(opts)
  opts.enable_filetypes = opts.enable_filetypes or enable_filetypes
  if opts.rule ~= nil then
    for key, r in pairs(opts.rule) do
      char_rule[key]= r
    end
  end
end

M.format = function(lineSkip)
  local pos = vim.fn.getpos('.')
  local line = vim.fn.getline('.')
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
  local quote_list = { '"', "'", '`' }
  local isInQuote = false
  local lastQuote = ""
  local charIndex = 0

  while charIndex < string.len(line) do
    charIndex = charIndex + 1
    for _, quote in pairs(quote_list) do
      if isInQuote == true
          and quote == line:sub(charIndex, charIndex)
          and quote == lastQuote
          and line:sub(charIndex -1,charIndex-1)~= "\\"
        then
        isInQuote = false
        break;
      end
      if isInQuote == false
        and quote == line:sub(charIndex , charIndex)
        then
        lastQuote = quote
        isInQuote = true
      end
    end
    if isInQuote == false then
      local char = line:sub(charIndex, charIndex)
      local rule = char_rule[char]
      if rule ~= nil then
        local pre_char = line:sub(charIndex - 1, charIndex - 1)
        local next_char = line:sub(charIndex + 1, charIndex + 1)
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
    end
  end
  vim.fn.setline(lnr, line)
end

return M
