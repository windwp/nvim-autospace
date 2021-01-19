local helpers = {}
local auto_space = require("nvim-autospace")

auto_space.setup({
    rule = {
      ['$']= {
        before = {prev = "[a-zA-Z0-9'\"%]%)]", next = "."},
        after  = {prev = ".", next = "[a-zA-Z0-9'\"%(]"}
      },
    }
  })
local eq = assert.are.same

function helpers.feed(text, feed_opts)
  feed_opts = feed_opts or 'n'
  local to_feed = vim.api.nvim_replace_termcodes(text, true, false, true)
  vim.api.nvim_feedkeys(to_feed, feed_opts, true)
end

function helpers.insert(text)
  helpers.feed('i' .. text, 'x')
end

local data = {
  {
    name = "normal space" ,
    filetype = "lua",
    before = [[local a=a+b]],
    after  = [[local a = a + b]]
  },
  {
    name = "lua  ~ char" ,
    filetype = "lua",
    before = [[if a~=a+b then]],
    after  = [[if a ~= a + b then]]
  },
  {
    name = "lua  .. char" ,
    filetype = "lua",
    before = [["aa".."bb"]],
    after  = [["aa" .. "bb"]]
  },
  {
    name = "javascript char !" ,
    filetype = "javascript",
    before = [[if(a!=a+b) then]],
    after  = [[if(a != a + b) then]]
  },
  {
    name = "char + before char ] " ,
    filetype = "javascript",
    before = [[ a[2]+a[4] ]],
    after  = [[ a[2] + a[4] ]]
  },
  {
    name = "char $ custom setup " ,
    filetype = "javascript",
    before = [[ a[2]$a[4] ]],
    after  = [[ a[2] $ a[4] ]]
  },
  {
    name = "char >" ,
    filetype = "javascript",
    before = [[local a>=b]],
    after  = [[local a >= b]]
  },
  {
    name = "char +  quote " ,
    filetype = "javascript",
    before = [['name' : '+replace']],
    after  = [['name' : '+replace']]
  },
  {
    name = "char - with number " ,
    filetype = "javascript",
    before = [[charIndex -(next_char[2]-prev_char[2]) -2;(-2+2-2)]],
    after  = [[charIndex - (next_char[2] - prev_char[2]) -2;(-2 + 2 -2)]]
  },
  {
    name = "char > empty char with single quote with quote",
    filetype = "vim",
    before = [[noremap <silent> <c-t>j V:m '>+1<CR>gv=gv]],
    after  = [[noremap <silent> <c-t>j V:m '>+1<CR>gv=gv]]
  },
  {
    name = "remove empty char on word" ,
    filetype = "javascript",
    before = [[ aaa   aaaa]],
    after  = [[ aaa aaaa]]
  },
  {
    name = "remove empty char on word not inside quote",
    filetype = "javascript",
    before = [[ aaa   aaaa "aa    \"aaa"   aaa   bbbb]],
    after  = [[ aaa aaaa "aa    \"aaa" aaa bbbb]]
  },
  {
    name = "remove empty char with single quote" ,
    filetype = "javascript",
    before = [[(dsada  ,      sadas          ,)]],
    after  = [[(dsada, sadas,)]]
  },
  {
    name = "remove empty char with single quote with quote" ,
    filetype = "javascript",
    before = [[(dsada  ,      sadas          ,"aaa   ,  a")]],
    after  = [[(dsada, sadas, "aaa   ,  a")]]
  },

}

local run_data = {}
for _, value in pairs(data) do
  if value.only == true then
    table.insert(run_data, value)
    break
  end
end
if #run_data == 0 then run_data = data end


describe('autospace ', function()
  for _, value in pairs(run_data) do
    it("test "..value.name, function()
      local before = string.gsub(value.before , '%|' , "")
      local after = string.gsub(value.after , '%|' , "")
      local line = 1
      if value.filetype ~= nil then
        vim.bo.filetype = value.filetype
      else
        vim.bo.filetype = "text"
      end
      vim.fn.setline(line , before)
      vim.fn.setpos('.' ,{0, line, 0, 0})
      auto_space.format(0)
      local result = vim.fn.getline(line)
      eq(after, result , "\n\n text error: " .. value.name .. "\n")
    end)
  end

  if #run_data > 1 then
    it("test skip filetype", function()
      vim.bo.filetype = "text"
      vim.fn.setline(1 , "a=a+b" )
      auto_space.format()
      local result = vim.fn.getline(1)
      eq("a = a + b", result , "file text error")
    end)
  end
end)


