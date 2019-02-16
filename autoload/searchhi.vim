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
    " Search for `nohlsearch` in this script and see comments there
    set hlsearch

    " We assume that `is_visual` is false by default, because calling
    " functions from visual mode will automatically exit visual mode
    "
    " Get optional arguments of function: `get(a:, nth arg, default)`
    let is_visual = get(a:, 1, 0)

    if !exists('g:searchhi_match')
        " Get the search pattern {{{

        " We need to make a pattern to match a specific search result of the
        " previous search query (we use the variable `query`). We do this by
        " specifying the line and column of that specific search result
        " (`start_line` and `start_column`)

        if exists('g:searchhi_match_line')
            let start_line = g:searchhi_match_line
        else
            let start_line = line('.')
        endif

        if exists('g:searchhi_match_column')
            let start_column = g:searchhi_match_column
        else
            let start_column = col('.')
        endif

        if exists('g:searchhi_match_query')
            let query = g:searchhi_match_query
        else
            let query = @/
        endif

        let multiline = query =~ "\n"
        if !multiline
            " The pattern is restricted to the line and column where the current
            " search result begins, using (`/\%l`) and (`/\%c`) respectively. The
            " previous search query is then used to finish the pattern
            let pattern =
                \ '\%' . start_line . 'l' .
                \ '\%' . start_column . 'c' .
                \ query

            " I think this already handles `smartcase` properly
            if &ignorecase
                let pattern .= '\c'
            endif

            let g:searchhi_match = matchadd("CurrentSearch", pattern)
        else
            let [end_line, end_column] = searchpos(query, 'cenW')
            let length = end_column - start_column + 1

            " This is more efficient than `matchadd` because it doesn't use a
            " regex. We use this if we don't have a multline search
            let g:searchhi_match = matchaddpos(
                \ "CurrentSearch",
                \ [[start_line, start_column, length]]
            \ )
        endif

        " }}}

        " Highlight the pattern and store the ID of the match in a script-wide
        " variable so that it can be deleted later, which will remove the
        " highlight
        "
        " These variables are global because there can only be one search
        " highlight active at one time
        let g:searchhi_match_window = win_getid()
        let g:searchhi_match_buffer = bufnr('%')
        let g:searchhi_match_line = start_line
        let g:searchhi_match_column = start_column
        let g:searchhi_match_query = query

        if g:searchhi_autocmds_enabled
            unsilent doautocmd <nomodeline> User SearchHiOn
        endif

        if g:searchhi_open_folds
            try
                " Try to open a fold (this will exit visual mode and go to
                " normal mode)
                normal! zo
                catch /^Vim\%((\a\+)\)\=:E490/
            endtry

            let is_visual = 0
        endif

        call searchhi#triggers_on()
    endif

    call s:restore_visual_maybe(a:expect_visual, is_visual)
endfunction

function! searchhi#off(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)

    " Whether the highlight is only temporarily turned off. If true, then
    " stuff needed to turn the highlight back on (without a new search)
    " is retained. This 'stuff' includes:
    " - autocmds (from auto-toggle)
    " - options containing information on the current search result (e.g. the
    "   query, line, column, buffer, and window)
    let tmp = get(a:, 2, 0)

    if exists('g:searchhi_match')
        let original_window = win_getid()

        let same_window = 0
        if (original_window == g:searchhi_match_window)
            let same_window = 1
        endif

        if !same_window
            " Move to the tab and window where the highlight is
            "
            " This can be false if the other window was closed.  If this true,
            " then it means that it exists and we have moved to it.
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

        if g:searchhi_autocmds_enabled
            unsilent doautocmd <nomodeline> User SearchHiOff
        endif
    endif

    if !tmp
        " Clear everything

        if !g:searchhi_trigger_always
            call searchhi#triggers_off()
        endif

        call searchhi#unlet_match_info()
    endif

    call s:restore_visual_maybe(a:expect_visual, is_visual)
endfunction

function! searchhi#update(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)
    let tmp = get(a:, 2, 0)

    call searchhi#off(a:expect_visual, is_visual, tmp)

    " The last function just fulfilled `a:expect_visual`, so we should update
    " `is_visual`
    let is_visual = a:expect_visual

    call searchhi#on(a:expect_visual, is_visual)

    " Note: since this function calls other functions (`searchhi#off` and
    " `searchhi#on`) that will call `s:restore_visual_maybe`, we don't need to
    " call it here
endfunction

" Cursor stay functions {{{

function! searchhi#on_stay(expect_visual, ...) range
    " This function should be called if the cursor might not be at the start
    " position of the current search result
    "
    " Essentially, if the cursor is inside a search result (not necessarily at
    " the start), then the whole search result will be highlighted
    "
    " An example when this would happen is after a 'stay search' was used. A
    " 'stay search' is basically a search where the cursor does not jump to
    " the position of the first search result. However, because the highlight
    " for the current search result works by defining the line and column
    " where the start of the highlight match must occur, we now need to find
    " that start position separately
    "
    " Another example when this would happen is when
    " `g:searchhi_update_tmp_events = 'CursorMoved'` and this function is
    " when the cursor moves

    let is_visual = get(a:, 1, 0)

    " 'b' -> Search backwards
    " 'c' -> Accept potential match at cursor
    " 'n' -> Don't move cursor
    " 'e' -> Get the position at the end of the match
    " 'W' -> Don not wrap to end of file
    "
    " If not found, then both are 0
    "
    " If inside or behind a search result, `end_line` and `end_column` will
    " actually match the search result BEFORE the one that's under the cursor.
    " This is because we don't use the 'c' flag (accept potential at cursor)
    " for that search
    let [end_line, end_column] = searchpos(@/, 'bneW')
    let [start_line, start_column] = searchpos(@/, 'bcnW')

    if start_line > end_line || start_column > end_column
        " This means that the cursor is currently inside a match
        let g:searchhi_match_line = start_line
        let g:searchhi_match_column = start_column
        call searchhi#on(a:expect_visual, is_visual)
    endif
endfunction

function! searchhi#update_stay(expect_visual, ...) range
    let is_visual = get(a:, 1, 0)
    let tmp = get(a:, 2, 0)

    call searchhi#off(a:expect_visual, is_visual, tmp)
    let is_visual = a:expect_visual
    call searchhi#on_stay(a:expect_visual, is_visual)
endfunction

function! searchhi#unlet_match_info()
    silent! unlet g:searchhi_match_window
    silent! unlet g:searchhi_match_buffer
    silent! unlet g:searchhi_match_query
    silent! unlet g:searchhi_match_line
    silent! unlet g:searchhi_match_column
endfunction

" }}}

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
    set hlsearch

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

" Trigger functions {{{

function! searchhi#triggers_on()
    augroup searchhi_triggers
        autocmd!

        if g:searchhi_handle_windows
            if g:searchhi_trigger_always
                autocmd WinLeave,BufLeave * silent call s:check_before('s:on_leave()')
                autocmd WinEnter,BufEnter * silent call s:check_before('s:on_enter()')
            else
                autocmd WinLeave,BufLeave * silent call s:on_leave()
                autocmd WinEnter,BufEnter * silent call s:on_enter()
            endif
        endif

        " `autocmd!` to replace the autocmds above

        if g:searchhi_trigger_always
            if g:searchhi_update_triggers_no_autocmd != ''
                execute 'autocmd! ' . g:searchhi_update_triggers_no_autocmd .
                    \ " * silent call s:check_before('s:update_from_trigger(0)')"
            endif

            if g:searchhi_update_triggers != ''
                execute 'autocmd! ' . g:searchhi_update_triggers .
                    \ " * silent call s:check_before('s:update_from_trigger(1)')"
            endif

            if g:searchhi_off_all_triggers != ''
                execute 'autocmd! ' . g:searchhi_off_all_triggers .
                    \ " * silent call s:check_before('s:off_all()')"
            endif
        else
            if g:searchhi_update_triggers_no_autocmd != ''
                execute 'autocmd! ' . g:searchhi_update_triggers_no_autocmd .
                    \ ' * silent call s:update_from_trigger(0)'
            endif

            if g:searchhi_update_triggers != ''
                execute 'autocmd! ' . g:searchhi_update_triggers .
                    \ ' * silent call s:update_from_trigger(1)'
            endif

            if g:searchhi_off_all_triggers != ''
                execute 'autocmd! ' . g:searchhi_off_all_triggers .
                    \ ' * silent call s:off_all()'
            endif
        endif
    augroup END
endfunction

function! searchhi#triggers_off()
    augroup searchhi_triggers
        autocmd!
    augroup END
endfunction

function! s:check_before(callback)
    if v:hlsearch
        " call searchhi#unlet_match_info()
        silent! unlet g:searchhi_match_query
        execute 'call ' . a:callback
    else
        let is_visual = searchhi#is_visual()
        call searchhi#off(is_visual, is_visual)
    endif
endfunction

function! s:on_leave()
    let is_visual = searchhi#is_visual()

    " We need to turn off autocmds before calling `searchhi#off` so that
    " autocmds that echo things out won't cause a prompt to appear. For
    " example, if the user tries to open FZF while search highlighting is on.
    "
    " Note: this might have unintended side effects, depending on what the
    " users' autocmds are

    let orig = g:searchhi_autocmds_enabled
    let g:searchhi_autocmds_enabled = 0

    call searchhi#off(is_visual, is_visual, 1)

    let g:searchhi_autocmds_enabled = orig
endfunction

function! s:on_enter()
    let is_visual = searchhi#is_visual()
    call searchhi#on_stay(is_visual, is_visual)
endfunction

function! s:update_from_trigger(use_autocmds)
    let is_visual = searchhi#is_visual()

    let orig = g:searchhi_autocmds_enabled
    let g:searchhi_autocmds_enabled = a:use_autocmds

    " We use `update_stay` instead of `update()` because we can't guarantee
    " that the cursor will be at the start of the search result
    call searchhi#update_stay(is_visual, is_visual, 1)

    let g:searchhi_autocmds_enabled = orig

    " This is an attempt to fix the issue where echos from `SearchHiOn` aren't
    " cleared from `g:searchhi_update_triggers_no_autocmd`
    if a:use_autocmds && !exists('g:searchhi_match')
        unsilent doautocmd <nomodeline> User SearchHiOff
    endif
endfunction

function! s:off_all()
    let is_visual = searchhi#is_visual()
    call searchhi#off(is_visual, is_visual)

    " Hack: because calling `:nohlsearch` will not work (see help page), we
    " completely turn off the option. As a consequence, we have to turn it
    " back on if we want to search again. Hopefully there are no side-effects
    " from directly setting the option
    set nohlsearch
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

function! searchhi#is_visual()
    " `=~#` is if regexp matches (case sensitive)
    " `mode(1)` returns the full name of the mode
    return mode(1) =~# "[vV\<C-v>]"
endfunction

" }}}

let &cpo = s:save_cpo
