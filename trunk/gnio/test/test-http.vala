using GLib;
using Gurl;

public class Test {
	static MainLoop loop;

	public static void main(string[] args) {
		var opener = new UriOpener();

		loop = new MainLoop(null, false);

		opener.open_async(new HttpRequest("http://www.google.com/", null), null, (sender, result) => {
			try {
				HttpResponse response = ((UriOpener) sender).open_finish(result);
				debug("got a response: %d", response.response_code);
			} catch (Error ex) {
				debug("ouch: \"%s\"", ex.message);
			}
			loop.quit();
		});

		loop.run();
	}
}
