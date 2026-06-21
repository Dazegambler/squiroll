[<EntryPoint>]
let main args =
    let port = 5001
    
    match args |> Array.toList with
    | [] -> printfn "Usage:SquirollFSLobby <port>\nUsing default port(5001)\n"
    | Port :: [] -> port = Port
    | _ -> printfn "Usage:SquirollFSLobby <port>\nUsing default port(5001)\n"
    
    UDP.begin port
    TCP.begin port
    BOT.begin port
    0
