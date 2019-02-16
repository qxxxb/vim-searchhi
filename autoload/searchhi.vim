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

    call searchhi#restore_visual(expect_visual, is_visual)
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
        augroup END
    endif

    call searchhi#restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#update(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    if exists('g:searchhi_force_ignorecase') && @/ !~ '\\c$'
        let @/ .= '\c'
    endif

    let query = @/

    let [end_line, end_column] = searchpos(query, 'bneW')
    let [start_line, start_column] = searchpos(query, 'bcnW')

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
                call searchhi#clear(expect_visual, is_visual)
                let is_visual = expect_visual
            else
                " Off -> On
                set hlsearch
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

            let g:searchhi_match = matchadd("CurrentSearch", pattern)

            let g:searchhi_match_query = query
            let g:searchhi_match_line = start_line
            let g:searchhi_match_column = start_column
            let g:searchhi_match_window = win_getid()
            let g:searchhi_match_buffer = bufnr('%')

            if g:searchhi_user_autocmds_enabled
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
        " Mkae Off -> Off as optimized as possible
        if exists('g:searchhi_match')
            " On -> Off
            call searchhi#clear(expect_visual, is_visual)
            let is_visual = expect_visual
        endif
    endif

    call searchhi#restore_visual(expect_visual, is_visual)
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
        silent! unlet g:searchhi_match_buffer
    endif

    call searchhi#restore_visual(expect_visual, is_visual)
endfunction

function! searchhi#clear_all(...) range
    let expect_visual = get(a:, 1, s:is_visual())
    let is_visual = get(a:, 2, s:is_visual())

    " Hack: Set the option directly
    set nohlsearch
    call searchhi#clear(expect_visual, is_visual)
endfunction

" Autocmd functions {{{

function! searchhi#await_cmdline_leave()
    if getcmdtype() == '/' || getcmdtype() == '?'
        call searchhi#listen()
    endif

    if exists('g:searchhi_force_ignorecase')
        unlet g:searchhi_force_ignorecase
    endif
endfunction

function! searchhi#listen_cmdline_leave()
    if getcmdtype() == '/' || getcmdtype() == '?'
        call searchhi#update()
    endif

    if exists('g:searchhi_force_ignorecase')
        unlet g:searchhi_force_ignorecase
    endif
endfunction

function! searchhi#listen_cmdline_enter()
    if getcmdtype() == '/' || getcmdtype() == '?'
        call searchhi#clear()
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

" }}}

" Helpers {{{

" A more accurate name would be `restore_visual_if_necessary` but that's too
" long
function! searchhi#restore_visual(expect_visual, is_visual)
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

function! s:is_visual()
    " `=~#` is if regexp matches (case sensitive)
    " `mode(1)` returns the full name of the mode
    return mode(1) =~# "[vV\<C-v>]"
endfunction

function! searchhi#force_ignorecase()
    let g:searchhi_force_ignorecase = 1
endfunction

" }}}

let &cpo = s:save_cpo
