# vim-searchhi

Highlight the current search result in a different style than the other search
results.

![Demo gif](https://i.imgur.com/lkRaJkH.gif)

## Credits

This plugin would not have existed without [vim-searchant]. It uses the same
basic implementation for highlighting the current search result.

## Features

- Smooth integration with standard search as well as other search-enhancing
  plugins (e.g. [vim-anzu], [vim-asterisk]).
- Behaves appropriately in Visual mode.
- Autocommands are provided and executed when highlighting is turned on and off.
- Stray highlights are removed from inactive windows and tabs.

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
  autocmd User SearchHiOff AnzuClearSearchStatus | echo ''
augroup END
```

Integration with [vim-asterisk]:

```vim
nmap * <Plug>(asterisk-*)<Plug>(searchhi-update)
nmap # <Plug>(asterisk-#)<Plug>(searchhi-update)
nmap g* <Plug>(asterisk-g*)<Plug>(searchhi-update)
nmap g# <Plug>(asterisk-g#)<Plug>(searchhi-update)

nmap z* <Plug>(asterisk-z*)<Plug>(searchhi-update-stay-forward)
nmap z# <Plug>(asterisk-z#)<Plug>(searchhi-update-stay-backward)
nmap gz* <Plug>(asterisk-gz*)<Plug>(searchhi-update-stay-forward)
nmap gz# <Plug>(asterisk-gz#)<Plug>(searchhi-update-stay-backward)

" These do not use the visual variant (`searchhi-v-update`) because these
" vim-asterisk commands only use the selected text as the search term, so there
" is no need to preserve the visual selection
vmap * <Plug>(asterisk-*)<Plug>(searchhi-update)
vmap # <Plug>(asterisk-#)<Plug>(searchhi-update)
vmap g* <Plug>(asterisk-g*)<Plug>(searchhi-update)
vmap g# <Plug>(asterisk-g#)<Plug>(searchhi-update)

" These all use the backward variant because the cursor is always at or in
" front of the start of the visual selection, so we need to search backwards to
" get to the start position
vmap z* <Plug>(asterisk-z*)<Plug>(searchhi-update-stay-backward)
vmap z# <Plug>(asterisk-z#)<Plug>(searchhi-update-stay-backward)
vmap gz* <Plug>(asterisk-gz*)<Plug>(searchhi-update-stay-backward)
vmap gz# <Plug>(asterisk-gz#)<Plug>(searchhi-update-stay-backward)
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

    autocmd User SearchHiOff set guicursor& | AnzuClearSearchStatus | echo ''
augroup END
```

[vim-searchant]: https://github.com/timakro/vim-searchant
[vim-anzu]: https://github.com/osyo-manga/vim-anzu
[vim-asterisk]: https://github.com/haya14busa/vim-asterisk
