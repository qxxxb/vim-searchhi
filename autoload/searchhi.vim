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

            execute 'autocmd! ' . g:searchhi_clear_all_autocmds .
                \ ' * silent call searchhi#clear_all()'

            execute 'autocmd! ' . g:searchhi_update_all_autocmds .
                \ ' * silent call searchhi#update_all()'
        augroup END
    endif

    call s:restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#update(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    let query = @/

    if exists('g:searchhi_force_ignorecase')
        let search_query = query . '\c'
    else
        let search_query = query
    endif

    if expect_visual
        " We need to do this so the cursor is at the end of position of the
        " visual selection
        call s:restore_visual(expect_visual, is_visual)
        let is_visual = expect_visual
    endif

    let [end_line, end_column] = searchpos(search_query, 'bneW')
    let [start_line, start_column] = searchpos(search_query, 'bcnW')

    if start_line > end_line || start_column > end_column
        " If one of them exists (`g:searchhi_match_column`), they all exist
        if !exists('g:searchhi_match') ||
         \ !exists('g:searchhi_match_column') ||
         \ g:searchhi_match_column != start_column ||
         \ g:searchhi_match_line != start_line ||
         \ g:searchhi_match_query != query
            " Off -> On || On -> On (different)

            if exists('g:searchhi_match')
                " On -> On (different)
                call searchhi#clear(0, 0)
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
                    normal! zo
                    catch /^Vim\%((\a\+)\)\=:E490/
                endtry

                let is_visual = 0
            endif
        endif
    else
        " Make Off -> Off as optimized as possible
        if exists('g:searchhi_match')
            " On -> Off
            call searchhi#clear(0, 0)
        endif
    endif

    if g:searchhi_status != 'listen'
        call searchhi#listen(0, 0)
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
endfunction

" Autocmd functions {{{

" Hack: if the search was aborted, wait a little bit before updating the
" search highlight. It's done this way because `CmdlineEnter` does not give
" the right cursor position, so we wait for it to get restored before updating
" the search highlight.
function! searchhi#search_abort_handler(timer)
    cal searchhi#update()
    unlet g:searchhi_search_abort_timer
endfunction

function! searchhi#search_complete_handler(timer)
    " -1 means do nothing
    if g:searchhi_search_complete_action == 1
        if g:searchhi_user_autocmds_enabled
            unsilent doautocmd <nomodeline> User SearchHiOn
        endif
    else
        if g:searchhi_user_autocmds_enabled == 0
            unsilent doautocmd <nomodeline> User SearchHiOff
        endif
    endif

    unlet g:searchhi_search_complete_action
    unlet g:searchhi_search_complete_timer
endfunction

function! searchhi#listen_cmdline_leave()
    if getcmdtype() == '/' || getcmdtype() == '?'
        if v:event.abort
            let g:searchhi_search_abort_timer =
                \ timer_start(
                    \ g:searchhi_search_abort_time,
                    \ 'searchhi#search_abort_handler'
                \ )
        else
            " The cursor is actually moved one column past the end of the search
            " result when this function is called, so we have to move it back
            noautocmd call cursor(line('.'), col('.') - 1)

            let orig_autocmd = g:searchhi_user_autocmds_enabled
            let g:searchhi_user_autocmds_enabled = 0

            let orig_on = exists('g:searchhi_match')

            call searchhi#update()

            let new_on = exists('g:searchhi_match')
            if orig_on == new_on
                let g:searchhi_search_complete_action = -1
            elseif orig_on && !new_on
                let g:searchhi_search_complete_action = 0
            elseif !orig_on && new_on
                let g:searchhi_search_complete_action = 1
            endif

            let g:searchhi_search_complete_timer =
                \ timer_start(
                    \ g:searchhi_search_complete_time,
                    \ 'searchhi#search_complete_handler'
                \ )

            let g:searchhi_user_autocmds_enabled = orig_autocmd

            if exists('g:searchhi_force_ignorecase')
                unlet g:searchhi_force_ignorecase
            endif
        endif
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
    if (getcmdtype() == '/' || getcmdtype() == '?') && v:event.abort
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
