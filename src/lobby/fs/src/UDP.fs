module UDP
open System
open System.Net
open System.Net.Sockets
open System.Text

let private rec loop stop =
    async {
        if not stop then
            do! Async.Sleep(100)
            return! loop stop
    }

let begin port =
    try
        let listener = UdpClient(port)
        let ep = IPEndPoint(IPAddress.Any, port)  
    with e -> printfn "UDP Sock failure: %s" e.Message;return null
