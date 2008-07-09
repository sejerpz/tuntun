using GLib;

namespace Gurl {
	[Compact]
	public class WebHeader {
		public string name;
		public string value;

		public WebHeader(string name, string value) {
			this.name = name;
			this.value = value;
		}
	}

	public class WebHeaderCollection : Object {
		private List<WebHeader> _headers;

		public void add(string name, string value) {
			_headers.append(new WebHeader(name, value));
		}

		public string? get(string name) {
			foreach (weak WebHeader header in _headers)
				if (header.name == name)
					return header.value;

			return null;
		}

		public weak List<WebHeader> get_list() {
			return _headers;
		}
	}

	public abstract class WebClientRequest : FilterOutputStream {
		public WebRequest request {get; construct set;}
	}

	public abstract class WebServerRequest : FilterInputStream {
		public WebRequest request {get; construct set;}
	}

	public abstract class WebRequest : Object {
		public string? method {get; set;}

		public string? content_type {get; set;}

		public string uri {
			get {
				return _uri_info.uri;
			}
			construct set {
				_uri_info = Uri.parse(value);
			}
		}

		public weak Uri uri_info {
			get {
				return _uri_info;
			}
		}

		private Uri _uri_info;

		public WebHeaderCollection headers {get; private set;}

		construct {
			headers = new WebHeaderCollection();
		}

//		public abstract void get_client_request(OutputStream stream) throws Error;

//		public abstract void get_server_request(InputStream stream) throws Error;

		public abstract void write(OutputStream stream) throws Error;

		public abstract void parse(InputStream stream) throws Error;
	}

	public abstract class WebResponse : Object {
		
	}
}
