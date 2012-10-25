"============================================================================
"File:        go.vim
"Description: Check go syntax using 'go build'
"Maintainer:  Kamil Kisiel <kamil@kamilkisiel.net>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================
function! SyntaxCheckers_go_GetLocList()

    " Use gofmt to check the syntax for the current file.
    let makeprg = 'gofmt %'
    let errorformat = '%f:%l:%c: %m,%-G%.%#'
    let errors = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat, 'defaults': {'type': 'e'} })

    " Do not perform further checks if errors were found.
    if !empty(errors)
        return errors
    endif

    " Check syntax with the go compiler.
    " Test files, i.e. files with a name ending in `_test.go`, are not
    " compiled by `go build`, therefore `go test` must be called for those.
    if match(expand('%'), '_test.go$') == -1
        let makeprg = 'go build -o /dev/null'
    else
        let makeprg = 'go test -c -o /dev/null'
    endif
    let errorformat = '%f:%l:%c:%m,%f:%l%m,%-G#%.%#'

    let oldcd = getcwd()
    exec 'lcd ' . fnameescape(expand('%:p:h'))
    let errors = SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
    exec 'lcd ' . fnameescape(oldcd)
    return errors
endfunction
