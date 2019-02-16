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

## Quick start
```vim
nmap / <Plug>(searchhi-/)
nmap ? <Plug>(searchhi-?)
nmap n <Plug>(searchhi-n)
nmap N <Plug>(searchhi-N)
nmap * <Plug>(searchhi-*)
nmap # <Plug>(searchhi-#)
nmap g* <Plug>(searchhi-g*)
nmap g# <Plug>(searchhi-g#)
nmap <silent> <C-L> <Plug>(searchhi-off-all)

vmap / <Plug>(searchhi-v-/)
vmap ? <Plug>(searchhi-v-?)
vmap n <Plug>(searchhi-v-n)
vmap N <Plug>(searchhi-v-N)
vmap * <Plug>(searchhi-v-*)
vmap # <Plug>(searchhi-v-#)
vmap g* <Plug>(searchhi-v-g*)
vmap g# <Plug>(searchhi-v-g#)
vmap <silent> <C-L> <Plug>(searchhi-v-off-all)
```

Integration with [vim-anzu]:
```vim
let g:searchhi_autocmds_enabled = 1
augroup searchhi
  autocmd!
  autocmd User SearchHiOn AnzuUpdateSearchStatusOutput
  autocmd User SearchHiOff echo ''
augroup END
```

Integration with [vim-asterisk]:
```vim
map * <Plug>(asterisk-*)<Plug>(searchhi-update)
map # <Plug>(asterisk-#)<Plug>(searchhi-update)
map g* <Plug>(asterisk-g*)<Plug>(searchhi-update)
map g# <Plug>(asterisk-g#)<Plug>(searchhi-update)

map z* <Plug>(asterisk-z*)<Plug>(searchhi-update-stay)
map z# <Plug>(asterisk-z#)<Plug>(searchhi-update-stay)
map gz* <Plug>(asterisk-gz*)<Plug>(searchhi-update-stay)
map gz# <Plug>(asterisk-gz#)<Plug>(searchhi-update-stay)
```

If you use the "keep cursor position" feature of [vim-asterisk] (i.e.
`let g:asterisk#keeppos = 1`), use this:
```vim
map * <Plug>(asterisk-*)<Plug>(searchhi-update-stay)
map # <Plug>(asterisk-#)<Plug>(searchhi-update-stay)
map g* <Plug>(asterisk-g*)<Plug>(searchhi-update-stay)
map g# <Plug>(asterisk-g#)<Plug>(searchhi-update-stay)

nmap n <Plug>(searchhi-n-stay)
nmap N <Plug>(searchhi-N-stay)

vmap n <Plug>(searchhi-v-n-stay)
vmap N <Plug>(searchhi-v-N-stay)
```

## Customization

### Highlight style

The current search result is highlighted with `CurrentSearch`.

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
let g:searchhi_autocmds_enabled = 1

augroup searchhi
    autocmd!

    autocmd User SearchHiOn
        \ set guicursor=
            \c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,
            \n-v:block-blinkwait20-blinkon20-blinkoff20 |
        \ AnzuUpdateSearchStatusOutput

    autocmd User SearchHiOff set guicursor& | echo ''
augroup END
```

### Off triggers

Highlighting for all search results can automatically be turned off with custom
autocommands. Example:

```vim
let g:searchhi_off_all_triggers = 'InsertEnter'
```

[vim-searchant]: https://github.com/timakro/vim-searchant
[vim-anzu]: https://github.com/osyo-manga/vim-anzu
[vim-asterisk]: https://github.com/haya14busa/vim-asterisk
