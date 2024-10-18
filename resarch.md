# research about the Async library for Ocaml

started by googling `async ocaml`  
looked at the folowing source https://opensource.janestreet.com/async/  
that did not contain much info about what could be done with the library  
found this link on the page https://v3.ocaml.org/p/async/latest/doc/Async/index.html
while this page contains a list of many thinks inside of the library, it does not apper to contain examples.

back to the google search  
found a link to the text book Real World OCaml  
this section appers to contain many examples of how to use the async library.  
the section is chaper 18 Concurrent Programming with Async

while attempting to get examples form the text book working and printing things to the standrd output, I could not figure out how to do it.  
after asking github copilet about it multiple times and looking at the sparse google search results nothing was working,  
I decided to ask chat GPT and here is the result that came back that actuly worked
```ocaml
let main () =
  print_endline "Hello, Async world!";
  (* Ensure the output is flushed before the program ends *)
  return ()

let () =
  (*kick off async opperations without blocking*)
  don't_wait_for (main ());
  (* This starts the Async scheduler *)
  never_returns (Scheduler.go ())
  (*never_returns is a command that signals to the compiler saying, syncronux execution will not continue past this point and this function will never return.
  A side effect of this is the program will not stop untill an outside force(ctrl C) acts or explcit shutdown call is made from withn*)
```

---
### Deferred data type

Many functions from async return a type of `'a Deferred.t` this type will contain the result of the function eventualy, but we can not use it diretcly.  
We could use patturn matching to check its contence, but there is no garentee that it will have the results when we do so.
The propper way to extract the contence once it is returned is the use `Deferred.bind`.  
This function has the folowing syntax: `val bind : 'a Deferred.t -> f:('a -> 'b Deferred.t) -> 'b Deferred.t` this is quite complex syntax to type out and read, but there is a shortcut.  
we can use the `>>=` opperator to prefoem the same function with the folloeing syntax: `'a Deferred.t >>= f:( 'a -> 'b Deferred.t)`
noteably this syntax also returns a `'a Deferred.t`  the same object that is required to be returned by the passed in result handling function. Given that making our own deferred type seems painful, it is a good thing that we can wrap our actual returned result in the function `return()`

## Async Examples

### Print File Contence

Using the information above, lets make a function that prints the contence of a file into the terminal:
```ocaml
let print_file filename =
    Reader.file_contents filename
    >>= fun text ->
    return(print_endline text);;
```
Here we use the Reader.file_contents function to get the contence of the passed in file name.  
Then ising the deferred opperator (>>=) we extract the results and print them to the console