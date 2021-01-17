## nvim-autospace
- add space on some special character
- No remove any whitespace
- No add space on charater inside quote
### Sample
``` lua
local a=a+b
-- become
local a = a + b
```
### Usage
`:lua require('nvim-autospace').format(0)` : format current line
`:lua require('nvim-autospace').format(-1)` : format line above
`:lua require('nvim-autospace').format()`+format line and dont' validate global filetype 

by default it doesn't mapping to any key on vim.
You need to do it
``` vim
" autoformat when press o or O
nnoremap <silent> o :lua require('nvim-autospace').format(0)<cr>o
nnoremap <silent> O :lua require('nvim-autospace').format(0)<cr>O

```

``` lua
MUtils.completion_confirm=function()
    -- do whateever you want on <cr>
    vim.defer_fn(function()
        require('nvim-autospace').format(-1)
    end,20)
    return "<cr>"
end

remap('i' , '<CR>','v:lua.MUtils.completion_confirm()', {expr = true , noremap = true})

```

### Override default value
``` lua
-- add $ to rule and it make a$b =>a $ b
require('auto_space').setup({
    rule = {
      ['$']= {
        before = {prev = "[a-zA-Z0-9'\"%]%)]", next = ".", ft = "lua"},
        after  = {prev = ".", next = "[a-zA-Z0-9'\"%(]"}
      },
    }
  })
```
Take a look at source code to understand how to make rule
