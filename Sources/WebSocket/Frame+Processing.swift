extension WebSocket {
    /// A helper that processes a frame and directs it to the proper handler.
    ///
    /// Automatically replies to `ping` and automatically handles `close`
    func processFrame(_ frame: Frame) {
        // Unmasks the data so it's readable
        frame.unmask()
        
        func processString() {
            // If this is an UTF-8 invalid string
            guard let string = frame.payload.string() else {
                self.connection.client.close()
                return
            }
            
            // Stream to the textStream's listener
            self.textStream.outputStream?(string)
        }
        
        func processBinary() {
            // Stream to the binaryStream's listener
            self.binaryStream.outputStream?(frame.payload)
        }
        
        switch frame.opCode {
        case .text:
            processString()
        case .binary:
            processBinary()
        case .ping:
            do {
                // reply the input
                let pongFrame = try Frame(op: .pong , payload: frame.payload, mask: frame.maskBytes, isMasked: self.connection.serverSide)
                self.connection.inputStream(pongFrame)
            } catch {
                self.connection.errorNotification.notify(of: error)
            }
        case .continuation:
            processBinary()
        case .close:
            self.connection.client.close()
        case .pong:
            return
        }
    }
}
