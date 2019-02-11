if exists('g:loaded_searchhi') || &cp
  finish
endif
let g:loaded_searchhi = 1

if !exists('g:searchhi_visual_maps_enabled')
    let g:searchhi_visual_maps_enabled = 1
endif

if !exists('g:searchhi_open_folds')
    let g:searchhi_open_folds = 1
endif

if !exists('g:searchhi_autocmds_enabled')
    let g:searchhi_autocmds_enabled = 0
endif

" Setting it to `Incsearch` works out surprisingly nicely
highlight default link CurrentSearch Incsearch

" Note: for the following `<Plug>` mappings, note that all of them have a
" parameter for `expect_visual`

" Mappings for replacing normal mode commands {{{

" These are here because of problems with recursive mappings. For example:
"
" `nmap / <Plug>(searchhi-pre_search)/`
"
" This tries to call the `pre_search` method before searching. However, this
" results in a recursive mapping. That said, `<Plug>` mappings still must be
" recursive, so the solution here is just to have separate `<Plug>` mappings
" that completely replace the functionality of the original normal mode
" command

noremap <Plug>(searchhi-/)
    \ :<C-U>call searchhi#pre_search(0)<CR>/

noremap <Plug>(searchhi-?)
    \ :<C-U>call searchhi#pre_search(0)<CR>?

noremap <silent> <Plug>(searchhi-n)
    \ n:<C-U>call searchhi#update(0)<CR>

noremap <silent> <Plug>(searchhi-N)
    \ N:<C-U>call searchhi#update(0)<CR>

noremap <silent> <Plug>(searchhi-*)
    \ *:<C-U>call searchhi#update(0)<CR>

noremap <silent> <Plug>(searchhi-#)
    \ #:<C-U>call searchhi#update(0)<CR>

noremap <silent> <Plug>(searchhi-g*)
    \ g*:<C-U>call searchhi#update(0)<CR>

noremap <silent> <Plug>(searchhi-g#)
    \ g#:<C-U>call searchhi#update(0)<CR>

" }}}

" General use mappings {{{

" Turns off highlighting for all seach results
noremap <silent> <Plug>(searchhi-off-all)
    \ :<C-U>nohlsearch<CR>:call searchhi#off(0)<CR>

" }}}

" Lower-level mappings {{{

" Useful when used in combination with other plug mappings from other plugins

" Can be used after `n` or `N`
noremap <silent> <Plug>(searchhi-update)
    \ :<C-U>call searchhi#update(0)<CR>

" This was specifically made to be compatible with 'stay star' motions from
" `vim-asterisk`, though it should also work for general cases as well. This
" is called a 'stay' motion because it correctly handles the case where the
" cursor doesn't jump to the position of the first search result
"
" The first parameter specifies the direction: `''` is forward and `'b'` is
" backward
noremap <silent> <Plug>(searchhi-update-stay-forward)
    \ :<C-U>call searchhi#update_stay('', 0)<CR>

noremap <silent> <Plug>(searchhi-update-stay-backward)
    \ :<C-U>call searchhi#update_stay('b', 0)<CR>

noremap <silent> <Plug>(searchhi-on)
    \ :<C-U>call searchhi#on(0)<CR>

noremap <silent> <Plug>(searchhi-off)
    \ :<C-U>call searchhi#off(0)<CR>

noremap <silent> <Plug>(searchhi-pre-search)
    \ :<C-U>call searchhi#pre_search(0)<CR>

" }}}

if g:searchhi_visual_maps_enabled
    " Mappings for replacing visual mode commands {{{

    noremap <Plug>(searchhi-v-/)
        \ :<C-U>call searchhi#pre_search(1)<CR>/

    noremap <Plug>(searchhi-v-?)
        \ :<C-U>call searchhi#pre_search(1)<CR>?

    noremap <silent> <Plug>(searchhi-v-n)
        \ n:<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-N)
        \ N:<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-*)
        \ *:<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-#)
        \ #:<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-g*)
        \ g*:<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-g#)
        \ g#:<C-U>call searchhi#update(1)<CR>

    " }}}

    " General use mappings {{{

    noremap <silent> <Plug>(searchhi-v-off-all)
        \ :<C-U>nohlsearch<CR>:call searchhi#off(1)<CR>

    " }}}

    " Lower-level mappings {{{

    noremap <silent> <Plug>(searchhi-v-update)
        \ :<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-update-stay-forward)
        \ :<C-U>call searchhi#update_stay('', 1)<CR>

    noremap <silent> <Plug>(searchhi-v-update-stay-backward)
        \ :<C-U>call searchhi#update_stay('b', 1)<CR>

    noremap <silent> <Plug>(searchhi-v-on)
        \ :<C-U>call searchhi#on(1)<CR>

    noremap <silent> <Plug>(searchhi-v-off)
        \ :<C-U>call searchhi#off(1)<CR>

    noremap <silent> <Plug>(searchhi-v-pre-search)
        \ :<C-U>call searchhi#pre_search(1)<CR>

    " }}}
endif
