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
  (*kick of async opperations without blocking*)
  don't_wait_for (main ());
  (* This starts the Async scheduler *)
  never_returns (Scheduler.go ())
  (*never_returns is a command that signlas to the compiler saying, syncronux execution will not continue past this point and this function will never return.
  A side effect of this is the program will not stop untill an outside force(ctrl C) acts or explcit shutdown call is made from withn*)
```