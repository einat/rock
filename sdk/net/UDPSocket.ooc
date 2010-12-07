import net/[Socket, Address, DNS, Exceptions]
import io/[Reader, Writer]
import berkeley into socket

/**
    A DATAGRAM based socket interface.
 */
UDPSocket: class extends Socket {
    remote: SocketAddress

    init: func() {
        //super(remote family(), SocketType DATAGRAM, 0)
    }

    /**
       Send data through this socket
       :param data: The data to be sent
       :param length: The length of the data to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withLength(data: Char*, length: SizeT, flags: Int, other: String, port: SizeT, resend: Bool) -> Int {
        ip := DNS resolveOne(other, SocketType DATAGRAM, AddressFamily IP4) // Ohai, IP4-specificness. TODO: Fix this
        remote := SocketAddress new(ip, port)
        init(remote family(), SocketType DATAGRAM, 0)

        bytesSent := socket sendTo(descriptor, data, length, flags, remote addr(), remote length())
        if (resend)
            while(bytesSent < length && bytesSent != -1) {
                dataSubstring := data as Char* + bytesSent
                bytesSent += socket sendTo(descriptor, dataSubstring, length - bytesSent, flags, remote addr(), remote length())
            }

        if(bytesSent == -1)
            SocketError new() throw()

        return bytesSent
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withFlags(data: String, flags: Int, other: String, port: SizeT, resend: Bool) -> Int {
        send(data toCString(), data size, flags, other, port, resend)
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withResend(data: String, other: String, port: SizeT, resend: Bool) -> Int { send(data, 0, other, port, resend) }

    /**
       Send a string through this socket with resend attempted for unsent data
       :param data: The string to be sent

       :return: The number of bytes sent
     */
    send: func(data: String, other: String, port: SizeT) -> Int { send(data, other, port, true) }

    /**
       Send a byte through this socket
       :param byte: The byte to send
       :param flags: Send flags
     */
    sendByte: func ~withFlags(byte: Char, flags: Int, other: String, port: SizeT) {
        send(byte&, Char size, flags, other, port, true)
    }

    /**
       Send a byte through this socket
       :param byte: The byte to send
     */
    sendByte: func(byte: Char, other: String, port: SizeT) { sendByte(byte, 0, other, port) }

    /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer
       :param flags: Receive flags

       :return: Number of received bytes
     */
    receive: func ~withFlags(chars: Char*, length: SizeT, flags: Int, other: String, port: Int) -> Int {
        ip := DNS resolveOne(other, SocketType DATAGRAM, AddressFamily IP4) // Ohai, IP4-specificness. TODO: Fix this
        remote := SocketAddress new(ip, port)
        init(remote family(), SocketType DATAGRAM, 0)

        bytesRecv := socket recvFrom(descriptor, chars, length, flags, remote addr(), remote length())
        if(bytesRecv == -1) {
            SocketError new() throw()
        }
        if(bytesRecv == 0) {
            connected? = false // disconnected!
        }
        return bytesRecv
    }

     /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer

       :return: Number of received bytes
     */
    receive: func ~withBuffer(buffer: Buffer, length: SizeT, other: String, port: Int) -> Int {
        assert (length <= buffer capacity)
        ret := receive(buffer data, length, 0, other, port)
        buffer setLength(ret)
        ret
    }

    receive: func(length: SizeT, other: String, port: Int) -> Buffer {
        buffer := Buffer new(length)
        receive(buffer, length, other, port)
        buffer
    }

    /**
       Receive a byte from this socket
       :param flags: Receive flags

       :return: The byte read
     */
    receiveByte: func ~withFlags(flags: Int, other: String, port: Int) -> Char {
        c: Char
        receive(c&, 1, 0, other, port)
        return c
    }

    /**
       Receive a byte from this socket

       :return: The byte read
     */
    receiveByte: func(other: String, port: Int) -> Char { receiveByte(0, other, port) }
}

