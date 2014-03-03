python import vim
python import sys
python sys.path.append(vim.eval('expand("<sfile>:h")'))
python import note
python import StringIO

"""""""""""""""""""""""""""""""""""""""""""
"" New Note
"""""""""""""""""""""""""""""""""""""""""""

function! NoteNewFunc(...)

   split

   if a:0 == 1
      let g:NoteID = a:1
      call NoteEditNote()
      edit ~/.note.TMP
   else
      let template = "NOTE\n\n\n\nTAGS\n\n"
      edit ~/.note.TMP
      execute "normal! ggdG"
      execute "normal! i".template
      let g:NoteID = 0
   endif

   execute "normal! 3G"
   augroup Note
      autocmd!
      autocmd BufUnload <buffer> call NoteAddNote()
   augroup END  " ends au group NoteAdd
   startinsert

endfunction

function! NoteAddNote()
python << endPython

ID = int(vim.eval("g:NoteID"))
if not ID:
   ID = None

db = note.mongoDB("note")

n = note.Note(db)
n.processNote()

if n.noteText:
   db.addItem("notes", {"noteText": n.noteText, "tags": n.tags}, ID)

endPython

augroup Note
   autocmd!
augroup END

unlet g:NoteID

endfunction

function! NoteEditNote()
python << endPython
db = note.mongoDB("note")

n = note.Note(db)
n.makeTmpFile(int(vim.eval("g:NoteID")))

endPython
endfunction

command! -nargs=? NoteNew call NoteNewFunc(<f-args>)

"""""""""""""""""""""""""""""""""""""""""""
"" New Todo
"""""""""""""""""""""""""""""""""""""""""""

function! TodoNewFunc(...)

   split
   if a:0 == 1
      let g:NoteID = a:1
      call NoteEditTodo()
      edit ~/.note.TMP
   else
      let template = "TODO\n\n\n\nDONE\n\n\n\nDATE - MM DD YY\n\n\n"
      execute "normal! ggVGd"
      execute "normal! i".template
      edit ~/.note.TMP
      let g:NoteID=0
   endif

   execute "normal! 3G"
   augroup Note
      autocmd!
      autocmd BufUnload <buffer> call NoteAddToDo()
   augroup END  " ends Note group
   startinsert

endfunction

function! NoteAddToDo()
python << endPython

db = note.mongoDB("note")

todo = note.ToDo(db)
todo.processTodo()

if todo.todoText:
   db.addItem("todos", {"todoText": todo.todoText, "done": todo.done, "date": todo.date})

endPython

augroup Note
   autocmd!
augroup END
unlet g:NoteID

endfunction

function! NoteEditTodo()
python << endPython
db = note.mongoDB("note")

t = note.ToDo(db)
t.makeTmpFile(int(vim.eval("g:NoteID")))

endPython
endfunction

command! -nargs=? NoteToDo call TodoNewFunc(<f-args>)

"""""""""""""""""""""""""""""""""""""""""""
"" New Contact
"""""""""""""""""""""""""""""""""""""""""""

function! NoteContactFunc()

   split

   if a:0 == 1
      let g:NoteID = a:1
      call NoteEditContact()
      edit ~/.note.TMP
   else
      let template = "NAME\n\n\n\nAFFILIATION\n\n\n\nEMAIL\n\n\n\nMOBILE PHONE\n\n\n\nHOME PHONE\n\n\n\nWORK PHONE\n\n\n\nADDRESS\n\n\n"
      edit ~/.note.TMP
      execute "normal! ggdG"
      execute "normal! i".template
      let g:NoteID = 0
   end

   execute "normal! 3G"
   
   augroup Note
      autocmd!
      autocmd BufUnload <buffer> call NoteAddContact()
   augroup END  " ends au group NoteAdd

   startinsert

endfunction

function! NoteAddContact()
python << endPython

ID = int(vim.eval("g:NoteID"))
if not ID:
   ID = None

db = note.mongoDB("note")

c = note.Contact(db)
c.processContact()

if c.contactInfo['NAME']:
   db.addItem("contacts", c.contactInfo, ID)

endPython

unlet g:NoteID
augroup Note
   autocmd!
augroup END

endfunction

function! NoteEditContact()
python << endPython
db = note.mongoDB("note")

n = note.Note(db)
n.makeTmpFile(int(vim.eval("g:NoteID")))

endPython
endfunction

command! -nargs=? NoteContact call NoteContactFunc(<f-args>)


"""""""""""""""""""""""""""""""""""""""""""
"" New Place
"""""""""""""""""""""""""""""""""""""""""""

function! NotePlaceFunc()

   split

   if a:0 == 1
      let g:NoteID = a:1
      call NoteEditPlace()
      edit ~/.note.TMP
   else
      edit ~/.note.TMP
      let template = "PLACE\n\n\n\nNOTES\n\n\n\nADDRESS\n\n\n\nTAGS\n\n\n"
      execute "normal! ggdG"
      execute "normal! i".template
   endif

   execute "normal! 3G"
   augroup Note
      autocmd!
      autocmd BufUnload <buffer> call NoteAddPlace()
   augroup END  " ends au group NoteAdd
   startinsert

endfunction

function! NoteAddPlace()
python << endPython

ID = int(vim.eval("g:NoteID"))
if not ID:
   ID = None

db = note.mongoDB("note")

p = note.Place(db)
p.processPlace()

if p.placeText:
   db.addItem("places", {"noteText": p.noteText,
                        "placeText": p.placeText,
                        "addressText": p.addressText,
                        "tags": p.tags}, ID)

endPython

augroup Note
   autocmd!
augroup END

unlet g:NoteID

endfunction

function! NoteEditPlace()
python << endPython
db = note.mongoDB("note")

n = note.Note(db)
n.makeTmpFile(int(vim.eval("g:NoteID")))

endPython
endfunction


command! -nargs=? NotePlace call NotePlaceFunc(<f-args>)

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

"""""""""""""""""""""""""""""""""""""""""""
"" Delete
"""""""""""""""""""""""""""""""""""""""""""

function! NoteDeleteFunc(...)
python << endPython

ID = int(vim.eval("a:1"))

db = note.mongoDB('note')
db.deleteItem(ID)

endPython
endfunction

command! -nargs=* NoteDelete call NoteDeleteFunc(<f-args>)
