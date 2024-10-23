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

### let%bind
oftain deferred operations are shortained further using the `let%bind` syntax ` let%bind text = Reader.file_contents filename in ...` the using text as a raw string.  
this can be used in a some what 
syncronus fassion   
NOTE: in order to use this you need to have ppx_let included in the dune project as a pre processor(after libraries): 
```dune
(preprocess (pps ppx_let))
```

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

### TCP echo server
a common async progaming task is netwoek connections. naturaly async has funtions for this.

```ocaml
(* Copy data from the reader to the writer, using the provided buffer
   as scratch space *)
let rec copy_blocks buffer r w =
  match%bind Reader.read r buffer with
  | `Eof -> return ()
  | `Ok bytes_read ->
    Writer.write w (Bytes.to_string buffer) ~len:bytes_read;
    let%bind () = Writer.flushed w in
    copy_blocks buffer r w;;

(** Starts a TCP server, which listens on the specified port, invoking
copy_blocks every time a client connects. *)
let run () =
    let host_and_port =
        Tcp.Server.create
        ~on_handler_error:`Raise
        (Tcp.Where_to_listen.of_port 8765)
        (fun _addr r w ->
            let buffer = Bytes.create (16 * 1024) in
            copy_blocks buffer r w)
    in
    ignore
        (host_and_port
        : (Socket.Address.Inet.t, int) Tcp.Server.t Deferred.t)
```
here we use `Reader.read` and `Writer.write` to read and wright data from the client.  
a TCP server Socket is created with `Tcp.Server.create` specifying what to do on error, what port to listen on and what to do with incomming client connections

another way we could tranfer the data from the input to the output is using the async pipe interface
```ocaml
Pipe.transfer
  (Reader.pipe r)
  (Writer.pipe w)
  ~f:(if uppercase then String.uppercase else Fn.id)
```
NOTE: this is an example of a map funtion where the paremer f is the definition of how to tranform the input data  
`uppercase` is a passed in boolean value `String.uppercase_ascii` is a function. and I have no idea what `Fn.id` is  

### Http Requests

another common use of async programing is doing http requests.  
while Async does not directly contain an http request system, extention libraries do.  
this examples uses the `uri` and `cohttp-async` libraies, note: you will have to install both of them through opam before building or using dune install if allready configured in the workspace 

```ocaml
let query_uri query =
  let base_uri =
    Uri.of_string "http://api.duckduckgo.com/?format=json"
  in
  Uri.add_query_param base_uri ("q", [ query ])

let get_definition word =
  let%bind _, body = Cohttp_async.Client.get (query_uri word) in
  Cohttp_async.Body.to_string body >>= fun text -> return(print_endline text)
```

here we the uri library to form the request uri adding the querry parameter q with the passed in value.   
then we use Cohttp_async to send the request and extract the responce body  
various other text processing libraries and mothods can be used to analyze the responce  
NOTE: `Cohttp_async.Client.get` only returns the headres associated with the request. `Cohttp_async.Body.to_string` actualy gets the data recieved fromt he request  
NOTE: the api used in this example does not exist like that any more 