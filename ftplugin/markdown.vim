let s:preview_running = 0

if exists('g:md_pdf_viewer')
    let s:pdf_viewer = g:md_pdf_viewer
else 
    for possible_pdf in ['okular', 'mupdf', 'evince']
        if executable(possible_pdf)
            let s:pdf_viewer = possible_pdf
        endif
    endfor
endif

if exists('g:md_args')
    let s:args = g:md_args
else
    let s:args = ""
end

if (!exists('s:pdf_viewer'))
    echoh1 ErrorMsg
    echo "could not find valid pdf viewer"
    echoh1 None
    finish
endif

if exists(':AsyncRun') && v:version >= 800
    let s:async_support = 1
endif

function! s:CompileSynchronous()
"    execute "silent !pandoc " .s:args. " " . shellescape("%") "-o" shellescape("%<.pdf") "&>/dev/null && pkill -HUP mupdf &> /dev/null"
    "execute "silent !pandoc " . s:args . " " . shellescape("%") . " -o " . shellescape("%<.pdf") . " &>/dev/null && pkill -HUP mupdf &> /dev/null"

    " Construct the command
    
" Construct the command with expanded '%'
    let command = "silent !pandoc " . s:args . " " . shellescape(expand("%")) . " -o " . shellescape(expand("%<.pdf")) . " &>/dev/null && pkill -HUP mupdf &> /dev/null"
    
    " Convert the command string to a list and write it to a file
    call writefile([command], expand('~/vimplugindebug'))
    
    " Execute the command
    execute command

endfunction

function! s:CompileAsynchronous()
    execute "AsyncRun pandoc " . s:args. " % -o %<.pdf && pkill -HUP mupdf"
endfunction

function! s:CompileMd()
    " Only compile when the preview is enabled
    if (s:preview_running == 1)
        if exists('s:async_support')
            call s:CompileAsynchronous()
        else
            call s:CompileSynchronous()
        endif
    endif
    redraw!
endfunction

function! s:OpenPdf(pdf_viewer)
    " A synchronous (locking up) call is necessary here. Otherwise the pdf viewer will open before 
    " the file has been compiled, hence finding nothing to display.
    call s:CompileSynchronous()
    execute "silent !" .a:pdf_viewer shellescape("%<.pdf") "&> /dev/null &"
    redraw!
endfunction

function! s:StartPreview(pdf_viewer)
    let s:preview_running = 1
    call s:OpenPdf(a:pdf_viewer)
endfunction


" Use VIM-detected filetype to work nicely alongside standard VIM,
" other VIM Markdown plugins, and `vim-pandoc`
autocmd BufWritePost * if (&filetype == "pandoc" || &filetype == "markdown") | call s:CompileMd() | endif

command! StartMdPreview call s:StartPreview(s:pdf_viewer)
command! StopMdPreview let s:preview_running = 0

