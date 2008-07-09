using GLib;

public class SocketTest : Object {
	public void run() {
		Socket client;
		Socket socket = new Socket(SocketDomain.INET, SocketType.STREAM, null);

		socket.set_reuse_address(true);

		socket.set_blocking(false);

		try {
			socket.bind(new InetSocketAddress(new Inet4Address.loopback(), 31882));
		} catch (Error ex) {
			message("error binding socket: %s", ex.message);
		}

		try {
			socket.listen();
		} catch (Error ex) {
			message("error listening on socket: %s", ex.message);
		}

		try {
			client = socket.accept();
		} catch (Error ex) {
			message("error accepting connection: %s", ex.message);
		}

		if (client != null) {
			try {
				client.send("Hello, world!\r\n", 15);
			} catch (Error ex) {
				message("error sending message: %s", ex.message);
			}
		}
	}

	public static void main(string[] args) {
		GLib.Test.init(ref args);

		GLib.Test.add_func("/gnio/socket", () => {
			new SocketTest().run();
		});

		GLib.Test.run();
	}
}
