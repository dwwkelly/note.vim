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

function! NoteSearchFunc(searchTerm)
python << endPython

runner = note.Runner()
runner.command = "search"
old_stdout = sys.stdout
sys.stdout = mystdout = StringIO.StringIO()
runner.search([vim.eval("a:searchTerm")], color=False)
sys.stdout = old_stdout

f = os.path.expanduser("~/.noteSearch.TMP")
with open(f, 'w') as fd:
   fd.write(mystdout.getvalue())

vim.command('rightbelow split {0}'.format(f))
vim.command('setlocal buftype=nowrite')

endPython
endfunction

"command! -nargs=* NoteSearch call s:NoteSearchFunc(<f-args>)
