using GLib;

public class ResolverTest : Object {
	MainLoop loop;
	InetAddress address;
	Resolver resolver;

	public void run() {
		resolver = new Resolver();

		loop = new MainLoop(null, false);

		try {
			address = resolver.resolve("127.0.0.1", null);
		} catch (Error ex) {
			message("error resolving address: %s", ex.message);
		}

		message("resolved to %s", address.to_string());

		resolver.resolve_async("www.google.com", null, (source, result) => {
			try {
				address = resolver.resolve_finish(result);

				message("resolved to %s", address.to_string());
			} catch (Error ex) {
				message("error resolving address: %s", ex.message);
			}

			loop.quit();
		});

		loop.run();
	}

	public static void main(string[] args) {
		GLib.Test.init(ref args);

		GLib.Test.add_func("/gnio/address", () => {
			new ResolverTest().run();
		});

		GLib.Test.run();
	}
}
