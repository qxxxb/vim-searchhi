# TODO

- [x] `No matching autocommands`
  - Search with `/` returns prints that message
  - Fixed by upgrading to Neovim 0.4.4
- [x] Star doesn't search word under cursor
  - Can't reproduce
- [x] Searching with `/` with `clear_all_asap` doesn't work sometimes
  - CTRL-L doesn't work `clear_all_asap`
  - **Solution**: Delay after leaving command line
- [x] `incsearch` setting not working with `clear_all_asap` sometimes
  - Search for a string using `/`
  - Hit `l` to clear it
  - Search for another string using `/`
  - Notice that search results are not highlighted as you type, as would
    be expected of `incsearch`
  - Press `<CTRL-L>`
  - Search for a string using `/`
  - Notice that `incsearch` seems to be working again
  - **Solution**: Not sure what fixed this, but I can't reproduce anymore
- [ ] Autocommands aren't execute properly with `/`
  - Search for a string using `/`
  - You should see the autocommands execute
  - Search for another string using '/'
  - You won't see the autocommands execute
