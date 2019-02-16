if exists('g:loaded_searchhi') || &cp
  finish
endif
let g:loaded_searchhi = 1

if !exists('g:searchhi_user_autocmds_enabled')
    let g:searchhi_user_autocmds_enabled = 0
endif

if !exists('g:searchhi_clear_all_autocmds')
    let g:searchhi_clear_all_autocmds = ''
endif

if !exists('g:searchhi_open_folds')
    let g:searchhi_open_folds = 1
endif

if !exists('g:searchhi_visual_maps_enabled')
    let g:searchhi_visual_maps_enabled = 1
endif

" Setting it to `Incsearch` works out surprisingly nicely
highlight default link CurrentSearch Incsearch

let g:searchhi_status = ''
call searchhi#await()

noremap <silent> <Plug>(searchhi-listen)
    \ :<C-U>call searchhi#listen(0, 0)<CR>

noremap <silent> <Plug>(searchhi-await)
    \ :<C-U>call searchhi#await(0, 0)<CR>

noremap <silent> <Plug>(searchhi-update)
    \ :<C-U>call searchhi#update(0, 0)<CR>

noremap <silent> <Plug>(searchhi-clear)
    \ :<C-U>call searchhi#clear(0, 0)<CR>

" Convenience mappings

map <silent> <Plug>(searchhi-clear-all)
    \ :nohlsearch<CR><Plug>(searchhi-clear)<Plug>(searchhi-await)

noremap <silent> <Plug>(searchhi-n)
    \ :<C-U>call searchhi#listen(0, 0)<CR>n

noremap <silent> <Plug>(searchhi-N)
    \ :<C-U>call searchhi#listen(0, 0)<CR>N

noremap <silent> <Plug>(searchhi-*)
    \ :call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>*

noremap <silent> <Plug>(searchhi-g*)
    \ :<C-U>call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>g*

noremap <silent> <Plug>(searchhi-#)
    \ :call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>#

noremap <silent> <Plug>(searchhi-g#)
    \ :<C-U>call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>g#

noremap <silent> <Plug>(searchhi-gd)
    \ :<C-U>call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>gd

noremap <silent> <Plug>(searchhi-gD)
    \ :<C-U>call searchhi#listen(0, 0)<CR>
     \:<C-U>call searchhi#force_ignorecase(0, 0)<CR>gD

if g:searchhi_visual_maps_enabled
    noremap <silent> <Plug>(searchhi-v-listen)
        \ :<C-U>call searchhi#listen(1, 0)<CR>

    noremap <silent> <Plug>(searchhi-v-await)
        \ :<C-U>call searchhi#await(1, 0)<CR>

    noremap <silent> <Plug>(searchhi-v-clear)
        \ :<C-U>call searchhi#clear(1, 0)<CR>

    noremap <silent> <Plug>(searchhi-v-update)
        \ :<C-U>call searchhi#update(1, 0)<CR>

    noremap <silent> <Plug>(searchhi-v-clear-all)
        \ :<C-U>call searchhi#clear(0, 0)<CR>
         \:<C-U>nohlsearch<CR>
         \:<C-U>call searchhi#await(1, 0)<CR>

    noremap <silent> <Plug>(searchhi-v-n)
        \ :<C-U>call searchhi#listen(1, 0)<CR>n

    noremap <silent> <Plug>(searchhi-v-N)
        \ :<C-U>call searchhi#listen(1, 0)<CR>N

    noremap <silent> <Plug>(searchhi-v-*)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>*

    noremap <silent> <Plug>(searchhi-v-g*)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>g*

    noremap <silent> <Plug>(searchhi-v-#)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>#

    noremap <silent> <Plug>(searchhi-v-g#)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>g#

    noremap <silent> <Plug>(searchhi-v-gd)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>gd

    noremap <silent> <Plug>(searchhi-v-gD)
        \ :<C-U>call searchhi#listen(0, 0)<CR>
         \:<C-U>call searchhi#force_ignorecase(1, 0)<CR>gD
endif
