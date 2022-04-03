let s:save_cpo = &cpo
set cpo&vim

" Await mode should be used when search highlighting is off
function! searchhi#await(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if g:searchhi_status != 'await'
        let g:searchhi_status = 'await'

        augroup searchhi_internal
            autocmd!
            autocmd CmdLineLeave * silent call searchhi#await_cmdline_leave()
        augroup END
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

" Listen mode should be used when search highlighting is on. The plugin
" 'listens' for any events (e.g. `CursorMoved`) that might update the current
" search result
function! searchhi#listen(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if g:searchhi_status != 'listen'
        let g:searchhi_status = 'listen'

        augroup searchhi_internal
            autocmd!

            autocmd CursorMoved,WinEnter,BufEnter *
                \ silent call searchhi#update()

            autocmd WinLeave,BufLeave * silent call searchhi#listen_leave()

            autocmd CmdlineLeave * silent call searchhi#listen_cmdline_leave()
            autocmd CmdlineEnter * silent call searchhi#listen_cmdline_enter()

            if len(g:searchhi_clear_all_autocmds) > 0
                execute 'autocmd! ' . g:searchhi_clear_all_autocmds .
                    \ ' * silent call searchhi#clear_all()'
            endif

            if len(g:searchhi_update_all_autocmds) > 0
                execute 'autocmd! ' . g:searchhi_update_all_autocmds .
                    \ ' * silent call searchhi#update_all()'
            endif
        augroup END
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#update(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if g:searchhi_status != 'listen'
        call searchhi#listen(0, 0)
    endif

    if expect_visual
        " We need to do this so the cursor is at the end position of the
        " visual selection
        call s:restore_visual(expect_visual, is_visual)
        let is_visual = expect_visual
    endif

    let query = @/

    if exists('g:searchhi_force_ignorecase')
        let search_query = query . '\c'
    else
        let search_query = query
    endif

    silent! let [end_line, end_column] = searchpos(search_query, 'bneW')
    silent! let [start_line, start_column] = searchpos(search_query, 'bcnW')

    if start_line > end_line || start_column > end_column
        if !exists('g:searchhi_match') ||
         \ !exists('g:searchhi_match_column') ||
         \ g:searchhi_match_column != start_column ||
         \ g:searchhi_match_line != start_line ||
         \ g:searchhi_match_query != query
            " Off -> On || On -> On (different)

            if exists('g:searchhi_match')
                " On -> On (different)
                call searchhi#clear(0, 0)

                if g:searchhi_clear_all_asap
                    set nohlsearch
                    call searchhi#await(0, 0)
                    call s:restore_visual(expect_visual, is_visual)
                    return
                endif
            else
                " Off -> On
                if !&hlsearch
                    set hlsearch
                endif
            endif

            " The pattern is restricted to the line and column where the
            " current search result begins, using (`/\%l`) and (`/\%c`)
            " respectively. The previous search query is then used to finish
            " the pattern
            let pattern =
                \ '\%' . start_line . 'l' .
                \ '\%' . start_column . 'c' .
                \ query

            " I think this already handles `smartcase` properly
            if &ignorecase
                let pattern .= '\c'
            endif

            let g:searchhi_match = matchadd('CurrentSearch', pattern)

            let g:searchhi_match_query = query
            let g:searchhi_match_line = start_line
            let g:searchhi_match_column = start_column
            let g:searchhi_match_cursor_line = line('.')
            let g:searchhi_match_cursor_column = col('.')
            let g:searchhi_match_window = win_getid()

            if g:searchhi_cursor && bufname('%') != '[Command Line]'
                let g:searchhi_cursor_match = matchadd('SearchCursor', '\%#')
            endif

            if g:searchhi_user_autocmds_enabled
                if g:searchhi_redraw_before_on
                    redraw
                endif

                unsilent doautocmd <nomodeline> User SearchHiOn
            endif

            if g:searchhi_open_folds
                try
                    " Try to open a fold (this will exit visual mode and go to
                    " normal mode)
                    normal! zO
                    catch /^Vim\%((\a\+)\)\=:E490/
                endtry

                let is_visual = 0
            endif
        elseif g:searchhi_clear_all_asap &&
             \ exists('g:searchhi_match') &&
             \ exists('g:searchhi_match_cursor_column') &&
             \ (
                 \ g:searchhi_match_cursor_column != col('.') ||
                 \ g:searchhi_match_cursor_line != line('.')
             \ )
                " Specific case of On -> On (same)

                call searchhi#clear(0, 0)
                set nohlsearch
                call searchhi#await(0, 0)
        endif
    else
        " Make Off -> Off as optimized as possible
        if exists('g:searchhi_match')
            " On -> Off
            call searchhi#clear(0, 0)

            if g:searchhi_clear_all_asap
                set nohlsearch
                call searchhi#await(0, 0)
            endif
        endif
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#clear(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if exists('g:searchhi_match')
        " On -> Off

        " All this logic for switching windows is only required when the
        " command-window is used, because that doesn't trigger `WinLeave` or
        " `BufLeave`

        let orig_window = win_getid()

        let same_window = 0
        if orig_window == g:searchhi_match_window
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

            if g:searchhi_cursor && exists('g:searchhi_cursor_match')
                call matchdelete(g:searchhi_cursor_match)
                silent! unlet g:searchhi_cursor_match
            endif
        endif

        if !same_window && match_window_exists
            " Move back to the original window
            noautocmd call win_gotoid(orig_window)

            " If there was a visual selection before we moved to another
            " window, it got clobbered
            let is_visual = 0
        endif

        if g:searchhi_user_autocmds_enabled
            unsilent doautocmd <nomodeline> User SearchHiOff
        endif

        unlet g:searchhi_match
        silent! unlet g:searchhi_match_query
        silent! unlet g:searchhi_match_line
        silent! unlet g:searchhi_match_column
        silent! unlet g:searchhi_match_cursor_line
        silent! unlet g:searchhi_match_cursor_column
        silent! unlet g:searchhi_match_window
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#clear_all(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    " Hack: Set the option directly
    set nohlsearch
    call searchhi#clear(expect_visual, is_visual)
    call searchhi#await(0, 0)
endfunction

" Autocmd functions {{{

" Hack: if the search was aborted, wait a little bit before updating the
" search highlight. It's done this way because `CmdlineEnter` does not give
" the right cursor position, so we wait for it to get restored before updating
" the search highlight.

function! searchhi#cmdline_leave_handler(timer)
    call searchhi#update()

    if exists('g:searchhi_force_ignorecase')
        unlet g:searchhi_force_ignorecase
    endif

    if exists('g:searchhi_cmdline_leave_timer')
        unlet g:searchhi_cmdline_leave_timer
    endif
endfunction

function! searchhi#listen_cmdline_leave()
    if getcmdtype() == '/' || getcmdtype() == '?'
        let g:searchhi_cmdline_leave_timer =
            \ timer_start(
                \ g:searchhi_cmdline_leave_time,
                \ 'searchhi#cmdline_leave_handler'
            \ )
    endif
endfunction

function! searchhi#listen_cmdline_enter()
    if getcmdtype() == '/' || getcmdtype() == '?'
        call searchhi#clear()

        if exists('g:searchhi_force_ignorecase')
            unlet g:searchhi_force_ignorecase
        endif
    endif
endfunction

function! searchhi#listen_leave()
    " This is to prevent prompts from appearing if the users' autocmds use an
    " echo. An example is using anzu and calling FZF while highlighting is on
    let orig = g:searchhi_user_autocmds_enabled
    let g:searchhi_user_autocmds_enabled = 0

    call searchhi#clear()

    let g:searchhi_user_autocmds_enabled = orig
endfunction

function! searchhi#await_cmdline_leave()
    if (getcmdtype() == '/' || getcmdtype() == '?') &&
      \ has_key(v:event, 'abort') && v:event.abort
        call searchhi#clear_all()
    else
        call searchhi#listen_cmdline_leave()
    endif
endfunction

function! searchhi#update_all()
    if !&hlsearch
        set hlsearch
    endif

    call searchhi#update()
endfunction

function! searchhi#hlsearch(...)
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if !&hlsearch
        set hlsearch
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

" }}}

" Helpers {{{

" A more accurate name would be `restore_visual_if_necessary` but that's too
" long
function! s:restore_visual(expect_visual, is_visual)
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

function! searchhi#force_ignorecase(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    let g:searchhi_force_ignorecase = 1

    call s:restore_visual(expect_visual, is_visual)
endfunction

function! s:is_visual()
    " `=~#` is if regexp matches (case sensitive)
    " `mode(1)` returns the full name of the mode
    return mode(1) =~# "[vV\<C-v>]"
endfunction

" }}}

let &cpo = s:save_cpo
