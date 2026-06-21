namespace Socket
open System
open System.Net
open System.Net.Sockets
open System.Text

module TCP =
    let private init (port : int) =
        async {
            try
                let! host = Dns.GetHostEntryAsync(Dns.GetHostName()) |> Async.AwaitTask
                let ip = host.AddressList.[0]
                let listener = TcpListener(ip,port)
                listener.Server.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, 1)
                listener.Start()
                return listener
            with e -> printfn "TCP failure: %s" e.Message; return null
        }

module UDP =
    let private init (port : int) =
        async {
            try
                let listener = UdpClient(port)
                return listener
            with e -> printfn "UDP failure: %s" e.Message; return null
        }

    let run (port : int) =
        async {
            let! listener = init port
            let!
        }
