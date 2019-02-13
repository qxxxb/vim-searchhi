let s:save_cpo = &cpo
set cpo&vim

" `expect_visual` is whether the previous visual selection should be
" reselected upon returning from the function. I say 'previous' instead of
" 'current' because calling functions from visual mode will automatically
" exit visual mode
"
" `range` needs to be here so that the function won't get called for each line
" when a visual selection is present
function! searchhi#on(expect_visual, ...) range
    " We assume that `is_visual` is false by default, because calling
    " functions from visual mode will automatically exit visual mode
    "
    " Get optional arguments of function: `get(a:, nth arg, default)`
    let is_visual = get(a:, 1, 0)

    " The line and column of the current search result (this is necessary for
    " matching that specific search result)
    let start_line = get(a:, 2, line('.'))
    let start_column = get(a:, 3, col('.'))

    if !exists('g:searchhi_match') && !s:in_cmdwin()
        " Highlight the search result under the cursor

        let prev_search = @/
        if s:is_very_magic(prev_search)
            " Hack: yank the highlighted text to get the literal text. As of
            " now I can't find a simple way to convert a very magic pattern to
            " a magic pattern. This hack actually seems to work well, however
            "
            " Use an arbitrary register (I chose 's')
            let tmp = getreg('s')
            normal! "sygn
            let prev_search = getreg('s')
            call setreg('s', tmp)
        endif

        " The pattern is restricted to the line and column where the current
        " search result begins, using (`/\%l`) and (`/\%c`) respectively. The
        " previous search, which is surrounded by a non-capturing group
        " (`/\%(`), is then used to finish the pattern
        let pattern =
            \ '\%' . start_line . 'l' .
            \ '\%' . start_column . 'c' .
            \ '\%(' . prev_search . '\)'

        " I think this already handles `smartcase` properly
        if &ignorecase
            let pattern .= '\c'
        endif

        " Highlight the pattern and store the ID of the match in a script-wide
        " variable so that it can be deleted later, which will remove the
        " highlight
        "
        " These variables are global because there can only be one search
        " highlight active at one time
        let g:searchhi_match = matchadd("CurrentSearch", pattern)
        let g:searchhi_match_window = win_getid()
        let g:searchhi_match_buffer = bufnr('%')
        let g:searchhi_match_line = start_line
        let g:searchhi_match_column = start_column

        if g:searchhi_autocmds_enabled
            doautocmd <nomodeline> User SearchHiOn
        endif

        if g:searchhi_open_folds
            try
                " Try to open a fold (this will exit visual mode and go to normal
                " mode)
                normal! zo
                catch /^Vim\%((\a\+)\)\=:E490/
            endtry

            let is_visual = 0
        endif

        augroup searchhi_auto_toggle
            autocmd!

            if g:searchhi_auto_toggle
                autocmd WinEnter,BufEnter * call s:on_enter()
                autocmd WinLeave,BufLeave * call s:on_leave()
            endif

            if g:searchhi_off_events != ''
                " `autocmd!` to replace the autocmds above
                execute 'autocmd! ' . g:searchhi_off_events .
                    \ ' * let is_visual = s:is_visual() | '.
                    \ 'call searchhi#off(is_visual, is_visual)'
            endif
        augroup END
    endif

    call s:restore_visual_maybe(a:expect_visual, is_visual)
endfunction

function! s:on_enter()
    if bufnr('%') == g:searchhi_match_buffer
        " Switching windows when the buffers are the same should preserve the
        " visual selection
        "
        " Since this function is called from an autocmd, we need to determine
        " ourselves if we're in visual mode or not.
        "
        " The line and colum numbers must be provided so that highlighting
        " will still work if the cursor is not in the same position.
        let is_visual = s:is_visual()
        call searchhi#on(
            \ is_visual,
            \ is_visual,
            \ g:searchhi_match_line,
            \ g:searchhi_match_column
        \ )
    endif
endfunction

function! s:on_leave()
    let is_visual = s:is_visual()
    " the `1` is for `from_auto_toggle`
    call searchhi#off(is_visual, is_visual, 1)
endfunction

function! searchhi#off(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)
    let from_auto_toggle = get(a:, 2, 0)

    if exists('g:searchhi_match') && !s:in_cmdwin()
        let original_window = win_getid()

        let same_window = 0
        if (original_window == g:searchhi_match_window)
            let same_window = 1
        endif

        if !same_window
            " Move to the tab and window where the highlight is
            "
            " This can be false if the other window was closed.  If this true,
            " then it means the it exists and we have moved to it.
            noautocmd let match_window_exists =
                \ win_gotoid(g:searchhi_match_window)
        endif

        if same_window || match_window_exists
            " Remove the highlight
            call matchdelete(g:searchhi_match)
        endif

        " We need to do this because this is our indication that highlighting
        " is off
        unlet g:searchhi_match

        if !same_window && match_window_exists
            " Move back to the original window
            noautocmd call win_gotoid(original_window)

            " If there was a visual selection before we moved to another
            " window, it got clobbered
            let is_visual = 0
        endif

        if !from_auto_toggle
            augroup searchhi_auto_toggle
                autocmd!
            augroup END

            unlet g:searchhi_match_window
            unlet g:searchhi_match_buffer
            unlet g:searchhi_match_line
            unlet g:searchhi_match_column
        endif

        if g:searchhi_autocmds_enabled
            doautocmd <nomodeline> User SearchHiOff
        endif
    endif

    call s:restore_visual_maybe(a:expect_visual, is_visual)
endfunction

function! searchhi#update(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)

    call searchhi#off(a:expect_visual, is_visual)

    " The last function just fulfilled `a:expect_visual`, so we should update
    " `is_visual`
    let is_visual = a:expect_visual

    call searchhi#on(a:expect_visual, is_visual)

    " Note: since this function calls other functions (`searchhi#off` and
    " `searchhi#on`) that will call `s:restore_visual_maybe`, we don't need to
    " call it here
endfunction

" Functions for `/` {{{

" In order to highlight the search result immediately after the search is
" entered, we have to remap `<CR>` in command-line mode to do what it usually
" does and then highlight the current search result
"
" Using an `autocmd` for `CmdlineLeave` does not work because it doesn't
" capture the search result in the register before the `autocmd` is called, I
" think
"
" This doesn't have an optional argument for `is_visual` because this function
" only returns a string for `cmap <CR>`
function! s:make_cr_cmap(expect_visual)
    if getcmdtype() == '/' || getcmdtype() == '?'
        return
            \ "\<CR>:call searchhi#post_search(" . a:expect_visual . ")\<CR>"
    else
        return "\<CR>"
    endif
endfunction

function! searchhi#post_search(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)

    cunmap <CR>

    " The needs to be before `searchhi#on` is called because if
    " `a:expect_visual` is true, then the visual selection must be reselected
    " so that the cursor will be put at the end of the selection, where the
    " start of the current search result is
    call s:restore_visual_maybe(a:expect_visual, is_visual)
    let is_visual = a:expect_visual

    call searchhi#on(a:expect_visual, is_visual)
endfunction

function! searchhi#pre_search(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)

    call searchhi#off(a:expect_visual, is_visual)
    " We don't do `let is_visual = a:expect_visual` because `is_visual` is not
    " used after this

    " This will be unmapped in `post_search`, but that is only if the user
    " actually submits the search query by hitting `<CR>`. If the user presses
    " `<ESC>` or does something else to exit command-line mode, then this will
    " be not unmapped. However, even if `make_cr_cmap` remains mapped to
    " `<CR>`, it should be harmless
    execute
        \ 'cnoremap <silent> <expr> <CR> <SID>make_cr_cmap(' .
        \ a:expect_visual . ')'
endfunction

" }}}

" Functions for 'stay search' motions from `vim-asterisk` {{{

function! searchhi#on_stay(direction, expect_visual, ...) range
    " This function should be called after a 'stay search' was used. A 'stay
    " search' is basically a search where the cursor does not jump to the
    " position of the first search result. However, because the highlight for
    " the current search result works by defining the line and column where
    " the start of the highlight match must occur, we now need to find that
    " start position separately

    " If the variable `direction` equals 'b', then the search is backwards. If
    " it's empty, then the search is forwards

    let is_visual = get(a:, 1, 0)

    if s:in_word()
        " If we started in a word, then we just go to the beginning of the
        " word by searching backwards
        let direction = 'b'
    else
        let direction = a:direction
    endif

    " Search in direction (`direction`), accept potential match at cursor
    " position (`'c'`), and do not move the cursor (`'n'`)
    let flags = direction . 'cn'
    " `@/` contains the previous search
    let [start_line, start_column] = searchpos(@/, flags)

    call searchhi#on(a:expect_visual, is_visual, start_line, start_column)
endfunction

function! searchhi#update_stay(direction, expect_visual, ...) range
    let is_visual = get(a:, 1, 0)

    call searchhi#off(a:expect_visual, is_visual)
    let is_visual = a:expect_visual
    call searchhi#on_stay(a:direction, a:expect_visual, is_visual)
endfunction

" }}}

" Helpers {{{

" A more accurate name would be `restore_visual_if_necessary` but that's too
" long
function! s:restore_visual_maybe(expect_visual, is_visual)
    if a:is_visual == a:expect_visual
        return
    elseif a:expect_visual && !a:is_visual
        " Reselect previous visual selection
        normal! gv
    elseif !a:expect_visual && a:is_visual
        " This will probably never get called in this script, but for
        " completeness here it is. This just returns to normal mode
        normal ''
    endif
endfunction

function! s:in_word()
    " Return whether the character under the cursor (found by using `/\%c`) is
    " over a word character (`/\w`). `=~` is 'if the regexp matches'
    return getline('.') =~ '\%' . col('.') . 'c\w'
endfunction

function! s:in_cmdwin()
    return bufnr('%') == '[Command Line]'
endfunction

function! s:is_visual()
    " `=~#` is if regexp matches (case sensitive)
    " `mode(1)` returns the full name of the mode
    return mode(1) =~# "[vV\<C-v>]"
endfunction

function s:is_very_magic(pattern)
    return a:pattern =~ '^\\v'
endfunction

" }}}

let &cpo = s:save_cpo
