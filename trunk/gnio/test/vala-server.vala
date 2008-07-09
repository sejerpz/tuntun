using GLib;

public class ValaServer : Object {
	MainLoop loop;
	SocketServer server;
	SocketConnection client;

	public void run() {
		loop = new MainLoop(null, false);

		server = new SocketServer(new InetSocketAddress(new Inet4Address.any(), 30583));

		server.accept_async(null, (source, result) => {
			try {
				var connection = ((SocketServer) source).accept_finish(result);

				debug("server: got connection from %s", ((InetSocketAddress) connection.socket.get_remote_address()).address.to_string());
			} catch (Error ex) {
				debug("server: error: %s", ex.message);
			}
		});

		client = new SocketConnection(new InetSocketAddress(new Inet4Address.loopback(), 30583));

		client.connect_async(null, (source, result) => {
			debug("client: connected");
			try {
				((SocketConnection) source).connect_finish(result);

				loop.quit();
			} catch (Error ex) {
				debug("client: error: %s", ex.message);
			}
		});

		loop.run();
	}

	public static void main(string[] args) {
		new ValaServer().run();
	}
}
