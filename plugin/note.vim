python import vim
python import sys
python sys.path.append(vim.eval('expand("<sfile>:h")'))
python import note
python import StringIO

"""""""""""""""""""""""""""""""""""""""""""
"" New Note
"""""""""""""""""""""""""""""""""""""""""""

function! NoteNewFunc()

   let template = "NOTE\n\n\n\nTAGS\n\n"

   split
   edit ~/.note.TMP
   execute "normal! ggVGd"
   execute "normal! i".template
   execute "normal! 3G"
   au BufUnload <buffer> call NoteAddNote()
   startinsert

endfunction

function! NoteAddNote()
python << endPython

db = note.mongoDB("note")

n = note.Note(db)
n.processNote()

if n.noteText:
   db.addItem("notes", {"noteText": n.noteText, "tags": n.tags})

endPython
endfunction

command! NoteNew call NoteNewFunc()

"""""""""""""""""""""""""""""""""""""""""""
"" Search
"""""""""""""""""""""""""""""""""""""""""""

function! NoteSearchFunc(...)
python << endPython

searchTerm = " ".join(vim.eval("a:000"))

if not searchTerm:
   vim.command("echo 'No Search Term'")
else:
   runner = note.Runner()
   runner.command = "search"
   old_stdout = sys.stdout
   sys.stdout = mystdout = StringIO.StringIO()
   runner.search([searchTerm], color=False)
   sys.stdout = old_stdout

   f = os.path.expanduser("~/.noteSearch.TMP")
   with open(f, 'w') as fd:
      fd.write(mystdout.getvalue())

   vim.command('augroup NoteSearch')
   vim.command('au BufRead .noteSearch.TMP syn match Error "^\d\+\s"')
   vim.command('au BufRead .noteSearch.TMP syn match VarId "\u\l\l,\s\u\l\l\ \d\{1,2}:"')
   vim.command('augroup END')
   vim.command('rightbelow split {0}'.format(f))
   vim.command('setlocal buftype=nowrite')
   vim.command('autocmd! NoteSearch')

endPython
endfunction

command! -nargs=* NoteSearch call NoteSearchFunc(<f-args>)
