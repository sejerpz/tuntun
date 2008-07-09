using GLib;

namespace Gurl {
	/* status codes for HTTP */
	public errordomain HttpStatusCode {
		CONTINUE = 100,
		SWITCHING_PROTOCOLS = 101,
		PROCESSING = 102,
		OK = 200,
		CREATED = 201,
		ACCEPTED = 202,
		NON_AUTHORITATIVE_INFORMATION = 203,
		NO_CONTENT = 204,
		RESET_CONTENT = 205,
		PARTIAL_CONTENT = 206,
		MULTI_STATUS = 207,
		IM_USED = 226,
		MULTIPLE_CHOICES = 300,
		MOVED_PERMANENTLY = 301,
		FOUND = 302,
		SEE_OTHER = 303,
		NOT_MODIFIED = 304,
		USE_PROXY = 305,
		TEMPORARY_REDIRECT = 306,
		BAD_REQUEST = 400,
		UNAUTHORIZED = 401,
		PAYMENT_REQUIRED = 402,
		FORBIDDEN = 403,
		NOT_FOUND = 404,
		METHOD_NOT_ALLOWED = 405,
		NOT_ACCEPTABLE = 406,
		PROXY_AUTHENTICATION_REQUIRED = 407,
		REQUEST_TIMEOUT = 408,
		CONFLICT = 409,
		GONE = 410,
		LENGTH_REQUIRED = 411,
		PRECONDITION_FAILED = 412,
		REQUEST_ENTITY_TOO_LARGE = 413,
		REQUEST_URI_TOO_LONG = 414,
		UNSUPPORTED_MEDIA_TYPE = 415,
		REQUEST_RANGE_NOT_SATISFIABLE = 416,
		EXPECTATION_FAILED = 417,
		UNPROCESSABLE_ENTITY = 422,
		LOCKED = 423,
		FAILED_DEPENDENCY = 424,
		UPGRADE_REQUIRED = 425,
		INTERNAL_SERVER_ERROR = 500,
		NOT_IMPLEMENTED = 501,
		BAD_GATEWAY = 502,
		SERVICE_UNAVAILABLE = 503,
		GATEWAY_TIMEOUT = 504,
		HTTP_VERSION_NOT_SUPPORTED = 505,
		INSUFFICIENT_STORAGE = 507,
		NOT_EXTENDED = 510,
	}

	public class HttpRequest : WebRequest {
		public string? data {
			get {
				return this._data;
			}
			construct set {
				this._data = value;
				if (value != null)
					this.method = "POST";
				else
					this.method = "GET";
			}
		}

		private string? _data;

		public HttpRequest(string uri, string? data) {
			this.uri = uri;
			this.data = data;
		}

		public override void write(OutputStream stream) throws Error {
			string line = "%s %s %s\r\n".printf(this.method, this.uri_info.path, "HTTP/1.1");
			stream.write(line, line.len(), null);
			this.write_headers(stream);
		}

		public override void parse(InputStream stream) throws Error {
		
		}

		public void write_headers(OutputStream stream) throws Error {
			foreach (weak WebHeader header in headers.get_list()) {
				string line = "%s: %s\r\n".printf(header.name, header.value);
				stream.write(line, line.len(), null);
			}
			stream.write("\r\n", 2, null);
		}
	}

	public class HttpResponse : FilterInputStream {
		public int response_code {get; set;}

		private DataInputStream input;

		public HttpResponse(InputStream stream) {
			this.base_stream = stream;
		}

		construct {
			this.input = new DataInputStream(this.base_stream);
		}

		public void read_status() throws Error {
			size_t length;

			string[] result = input.read_line(out length, null).split(" ", 3);

			if (strv_length(result) < 3)
				throw new UriError.FAILED("invalid status line");

			string version = result[0];

			int code = result[1].to_int();

			if (code < 100)
				throw new UriError.FAILED("invalid status line");

			this.response_code = code;
		}

		public void read_headers() throws Error {
			size_t length;

			debug("headers:");

			while (true) {
				string line = input.read_line(out length, null);

				if (line.strip() == "")
					break;

				string[] result = line.split(":", 2);

				debug("%s: %s", result[0].strip(), result[1].strip());
			}
		}
	}
}
