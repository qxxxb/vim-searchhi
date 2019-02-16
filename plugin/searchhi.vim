if exists('g:loaded_searchhi') || &cp
  finish
endif
let g:loaded_searchhi = 1

if !exists('g:searchhi_open_folds')
    let g:searchhi_open_folds = 1
endif

if !exists('g:searchhi_autocmds_enabled')
    let g:searchhi_autocmds_enabled = 0
endif

if !exists('g:searchhi_handle_windows')
    let g:searchhi_handle_windows = 1
endif

" We disable autocmds (i.e. `SearchHiOn` and `SearchHiOff`) for `CursorMoved`
" so the performance doesn't suck when you hold down a movement key (e.g. `j`
" or `l`)
if !exists('g:searchhi_update_triggers_no_autocmd')
    let g:searchhi_update_triggers_no_autocmd = 'CursorMoved'
endif

if !exists('g:searchhi_update_triggers')
    let g:searchhi_update_triggers = 'CursorHold'
endif

if !exists('g:searchhi_off_all_triggers')
    let g:searchhi_off_all_triggers = ''
endif

if !exists('g:searchhi_visual_maps_enabled')
    let g:searchhi_visual_maps_enabled = 1
endif

" Setting it to `Incsearch` works out surprisingly nicely
highlight default link CurrentSearch Incsearch

" Note: for the following `<Plug>` mappings, note that all of them have a
" parameter for `expect_visual`

" Standard mappings for replacing normal mode commands {{{

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

" Alternative mappings for replacing normal mode commands {{{

noremap <silent> <Plug>(searchhi-n-stay)
    \ n:<C-U>call searchhi#update_stay(0)<CR>

noremap <silent> <Plug>(searchhi-N-stay)
    \ N:<C-U>call searchhi#update_stay(0)<CR>

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

noremap <silent> <Plug>(searchhi-update-stay)
    \ :<C-U>call searchhi#update_stay(0)<CR>

noremap <silent> <Plug>(searchhi-off)
    \ :<C-U>call searchhi#off(0)<CR>

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

    " Alternative mappings for replacing normal mode commands {{{

    noremap <silent> <Plug>(searchhi-v-n-stay)
        \ n:<C-U>call searchhi#update_stay(1)<CR>

    noremap <silent> <Plug>(searchhi-v-N-stay)
        \ N:<C-U>call searchhi#update_stay(1)<CR>

    " }}}

    " General use mappings {{{

    noremap <silent> <Plug>(searchhi-v-off-all)
        \ :<C-U>nohlsearch<CR>:call searchhi#off(1)<CR>

    " }}}

    " Lower-level mappings {{{

    noremap <silent> <Plug>(searchhi-v-update)
        \ :<C-U>call searchhi#update(1)<CR>

    noremap <silent> <Plug>(searchhi-v-update-stay)
        \ :<C-U>call searchhi#update_stay(1)<CR>

    noremap <silent> <Plug>(searchhi-v-off)
        \ :<C-U>call searchhi#off(1)<CR>

    " }}}
endif
