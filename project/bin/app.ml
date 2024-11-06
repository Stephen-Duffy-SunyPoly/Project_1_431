open Core
open Async

let read_file filename =
  Monitor.try_with (fun () ->
    Reader.with_file filename ~f:(fun reader ->
      Reader.lines reader
      |> Pipe.to_list
      >>= fun lines ->
      let filtered = List.filter lines ~f:(fun line ->
        not (String.is_empty (String.strip line))) in
      return filtered))
  >>| function
  | Ok result -> result
  | Error _ -> []

let process_files filenames =
  Deferred.List.map filenames ~how:`Parallel ~f:read_file

let command =
  Command.async
    ~summary:"Process multiple files concurrently"
    Command.Param.(
      map
        (anon (sequence ("filename" %: string)))
        ~f:(fun filenames () ->
          process_files filenames
          >>= fun results ->
          Deferred.List.iter
            ~how:`Sequential  (* Added the ~how parameter *)
            (List.zip_exn filenames results)
            ~f:(fun (filename, lines) ->
              printf "File: %s\n" filename;
              List.iter lines ~f:(printf "  %s\n");
              Deferred.return ())))
              
let () = Command_unix.run command