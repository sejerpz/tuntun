using GLib;

public class AddressTest : Object {
	public void run() {
		InetAddress address = Inet4Address.from_string("127.0.0.1");

		assert(address.is_loopback);

		address = new Inet4Address.any();

		assert(address.to_string() == "0.0.0.0");

		address = new Inet6Address.loopback();

		assert(address.to_string() == "::1");
	}

	public static void main(string[] args) {
		GLib.Test.init(ref args);

		GLib.Test.add_func("/gnio/address", () => {
			new AddressTest().run();
		});

		GLib.Test.run();
	}
}
