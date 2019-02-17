# vim-searchhi

Highlight the current search result in a different style than the other search
results.

![Demo gif](https://raw.githubusercontent.com/qxxxb/vim-searchhi/assets/demo.gif)

## Credits

This plugin would not have existed without [vim-searchant]. It uses the same
basic implementation for highlighting the current search result.

## Features

- Smooth integration with standard search as well as other search-enhancing
  plugins (e.g. [vim-anzu], [vim-asterisk]).

- Behaves appropriately in Visual mode.

- Highlighting is updated predictably when the cursor is moved, as well as
  when switching buffers and windows. It can also automatically be turned off
  with custom autocommands.

- User autocommands are provided and executed when highlighting is turned on
  and off.

**Note**: This plugin uses a lot of `<Plug>` mappings. An alternative plugin is
[vim-searchlight], which has the same basic functionality but doesn't require
any mappings.

## Quick start
```vim
nmap n <Plug>(searchhi-n)
nmap N <Plug>(searchhi-N)
nmap * <Plug>(searchhi-*)
nmap g* <Plug>(searchhi-g*)
nmap # <Plug>(searchhi-#)
nmap g# <Plug>(searchhi-g#)
nmap gd <Plug>(searchhi-gd)
nmap gD <Plug>(searchhi-gD)

vmap n <Plug>(searchhi-v-n)
vmap N <Plug>(searchhi-v-N)
vmap * <Plug>(searchhi-v-*)
vmap g* <Plug>(searchhi-v-g*)
vmap # <Plug>(searchhi-v-#)
vmap g# <Plug>(searchhi-v-g#)
vmap gd <Plug>(searchhi-v-gd)
vmap gD <Plug>(searchhi-v-gD)

nmap <silent> <C-L> <Plug>(searchhi-clear-all)
vmap <silent> <C-L> <Plug>(searchhi-v-clear-all)
```

Integration with [vim-anzu]:
```vim
let g:searchhi_user_autocmds_enabled = 1
let g:searchhi_redraw_before_on = 1

augroup searchhi
    autocmd!

    autocmd User SearchHiOn AnzuUpdateSearchStatusOutput

    autocmd User SearchHiOff echo g:anzu_no_match_word
augroup END
```

Example with [vim-asterisk]:
```vim
map * <Plug>(asterisk-*)<Plug>(searchhi-update)
map # <Plug>(asterisk-#)<Plug>(searchhi-update)
map g* <Plug>(asterisk-g*)<Plug>(searchhi-update)
map g# <Plug>(asterisk-g#)<Plug>(searchhi-update)

map z* <Plug>(asterisk-z*)<Plug>(searchhi-update)
map z# <Plug>(asterisk-z#)<Plug>(searchhi-update)
map gz* <Plug>(asterisk-gz*)<Plug>(searchhi-update)
map gz# <Plug>(asterisk-gz#)<Plug>(searchhi-update)
```

## Customization

### Highlight style

The current search result is highlighted with `CurrentSearch`. It can be changed like so:
```vim
highlight CurrentSearch
    \ cterm=reverse,bold ctermfg=108 ctermbg=235
    \ gui=reverse,bold guifg=#8ec07c guibg=#282828
```

By default, `CurrentSearch` is linked to `Incsearch`, which works nicely if your
`Incsearch` and `Search` highlight groups are distinguishable.

### Autocommands

The autocommands `SearchHiOn` and `SearchHiOff` are executed when highlighting
is turned on or off. Below is an example that blinks the cursor when search
highlighting is turned on, making the cursor easier to find. [vim-anzu] is also
used to echo the search count.
```vim
let g:searchhi_user_autocmds_enabled = 1
let g:searchhi_redraw_before_on = 1

augroup searchhi
    autocmd!

    autocmd User SearchHiOn
        \ set guicursor=
            \c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,
            \n-v:block-blinkwait20-blinkon20-blinkoff20 |
        \ AnzuUpdateSearchStatusOutput

    autocmd User SearchHiOff set guicursor& | echo g:anzu_no_match_word
augroup END
```

### Autocmds for toggling search highlighting

Highlighting for all search results can be toggled with custom autocommands.
Example:
```vim
let g:searchhi_clear_all_autocmds = 'InsertEnter'
let g:searchhi_update_all_autocmds = 'InsertLeave'
```

[vim-searchant]: https://github.com/timakro/vim-searchant
[vim-anzu]: https://github.com/osyo-manga/vim-anzu
[vim-asterisk]: https://github.com/haya14busa/vim-asterisk
[vim-searchlight]: https://github.com/PeterRincker/vim-searchlight
