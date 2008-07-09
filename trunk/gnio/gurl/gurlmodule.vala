using GLib;
using Gurl;

public class HttpHandler : Handler {
	public override HttpResponse? handle_open(HttpRequest request) throws Error {
		if (request.uri_info.scheme != "http")
			return null;

		if (request.uri_info.port < 0)
			request.uri_info.port = 80;

		var resolver = new Resolver();

		var address = resolver.resolve(request.uri_info.hostname, null);

		debug("connecting to %s...", address.to_string());

		SocketConnection connection = new SocketConnection(new InetSocketAddress(address, (ushort) request.uri_info.port));

		connection.connect(null);

		OutputStream output = connection.output_stream;
		DataInputStream input = new DataInputStream(connection.input_stream);

		request.headers.add("Host", request.uri_info.hostname);

		request.write(output);

		size_t length;

		HttpResponse* response = new HttpResponse(connection.input_stream);

		response->read_status();
		response->read_headers();

		return response;
	}
}

namespace Module {
	[CCode(cname="g_io_module_load")]
	public void load(IOModule* module) {
		IOExtensionPoint.implement(UriOpener.EXTENSION_POINT_NAME, typeof (HttpHandler), "http-handler", 10);
	}

	[CCode(cname="g_io_module_unload")]
	public void unload(IOModule* module) {
		
	}
}
