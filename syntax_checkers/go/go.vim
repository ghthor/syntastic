"============================================================================
"File:        go.vim
"Description: Check go syntax using 'gofmt -l' followed by 'go [build|test]'
"Maintainer:  Kamil Kisiel <kamil@kamilkisiel.net>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================
" Use `let g:syntastic_go_checker_option_gofmt_write=1` to allow gofmt to
" format the source file. Default: disabled.

if exists("g:loaded_syntastic_go_go_checker")
    finish
endif
let g:loaded_syntastic_go_go_checker = 1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_go_go_IsAvailable() dict
    return executable('go') && executable('gofmt')
endfunction

function! SyntaxCheckers_go_go_GetLocList() dict
    " Check with gofmt first, since `go build` and `go test` might not report
    " syntax errors in the current file if another file with syntax error is
    " compiled first.
    let makeprg = self.makeprgBuild({
        \ 'exe': 'gofmt',
        \ 'args': '-l',
        \ 'tail': '> ' . syntastic#util#DevNull() })

    " Check the g:syntastic_go_checker_option_gofmt_write variable.
    if !exists('g:syntastic_go_checker_option_gofmt_write')
        let g:syntastic_go_checker_option_gofmt_write = 0
    endif

    " Use gofmt to check the syntax for the current file.
    " If the syntastic_go_checker_option_gofmt_write is set to 1, let `gofmt`
    " format the file. The default is for `gofmt` to just print to STDOUT.
    if g:syntastic_go_checker_option_gofmt_write == 1
        let makeprg = self.makeprgBuild({
                    \ 'exe': 'gofmt',
                    \ 'args': '-w -l',
                    \ 'tail': '%' })
    endif

    let errorformat =
        \ '%f:%l:%c: %m,' .
        \ '%-G%.%#'

    let errors = SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat,
        \ 'cwd': expand('%:p:h'),
        \ 'defaults': {'type': 'e'} })
    if !empty(errors)
        return errors
    endif

    " If the content of the file might have been changed due to
    " g:syntastic_go_checker_option_gofmt_write being enabled, the buffer must
    " be reloaded.
    if g:syntastic_go_checker_option_gofmt_write == 1
        let view = winsaveview()
        silent %!gofmt
        call winrestview(view)
    endif

    " Test files, i.e. files with a name ending in `_test.go`, are not
    " compiled by `go build`, therefore `go test` must be called for those.
    if match(expand('%'), '\m_test\.go$') == -1
        let makeprg = 'go build'
        let cleanup = 0
    else
        let makeprg = 'go test -c ' . syntastic#c#NullOutput()
        let cleanup = 1
    endif

    " The first pattern is for warnings from C compilers.
    let errorformat =
        \ '%W%f:%l: warning: %m,' .
        \ '%E%f:%l:%c:%m,' .
        \ '%E%f:%l:%m,' .
        \ '%C%\s%\+%m,' .
        \ '%-G#%.%#'

    " The go compiler needs to either be run with an import path as an
    " argument or directly from the package directory. Since figuring out
    " the proper import path is fickle, just cwd to the package.

    let errors = SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat,
        \ 'cwd': expand('%:p:h'),
        \ 'defaults': {'type': 'e'} })

    if cleanup
        call delete(expand('%:p:h') . syntastic#util#Slash() . expand('%:p:h:t') . '.test')
    endif

    return errors
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'go',
    \ 'name': 'go'})

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set et sts=4 sw=4:
