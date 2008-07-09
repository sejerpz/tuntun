using GLib;


public class Test : Object {
	public static void main(string[] args) {
		GLib.Test.init(ref args);

		foreach (Type child in typeof(UnitTest).children()) {
			((UnitTest) Object.new(child)).initialize();
		}

		GLib.Test.run();
	}
}
