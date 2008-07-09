using GLib;

namespace Gurl {
	/* todo: copy most of this from GVfs' gvfsuriutils.c */
	[Compact]
	public class Uri {
		public string uri;
		public string? path;
		public string? scheme;
		public string? fragment;
		public string? query;
		public string? netloc;
		public string? params;
		public string? hostname;
		public string? username;
		public string? password;
		public int port;

		private static bool scheme_uses_fragment(string? scheme) {
			if (scheme == "http" ||
			    scheme == "https" ||
			    scheme == "ftp")
				return true;
			return false;
		}

		private static bool scheme_uses_netloc(string? scheme) {
			if (scheme == "http" ||
			    scheme == "https" ||
			    scheme == "ftp" ||
			    scheme == "file")
				return true;
			return false;
		}

		private Uri(string uri, string path, string? scheme, string? netloc, string? fragment, string? query) {
			this.uri = uri;
			this.path = path;
			this.scheme = scheme;
			this.netloc = netloc;
			this.fragment = fragment;
			this.query = query;

			if (netloc == null)
				return;

			string* at = netloc.str("@");

			if (at != null) {
				string* usercolon = netloc.str(":");

				if (usercolon != null && (char*) usercolon < (char*) at - 1) {
					this.username = netloc.ndup((char*) usercolon - (char*) netloc);
					this.password = (usercolon + 1)->ndup((char*) at - (char*) usercolon - 1);
				} else {
					this.username = netloc.ndup((char*) at - (char*) netloc);
					this.password = null;
				}

				at = at + 1;
			} else {
				at = netloc;
			}

			string* portcolon = at->str(":");

			if (portcolon != null) {
				this.hostname = at->ndup(portcolon - at);
				this.port = (ushort) (portcolon + 1)->to_int();
			} else {
				this.hostname = at;
				this.port = -1;
			}
		}

		public static Uri parse(string uri, string? default_scheme = null) {
			string* urip = uri;

			string? scheme = default_scheme;
			string? netloc;
			string? fragment;
			string? query;

			string* end;
			string* colon;
			string* pound;
			string* question;

			string full_uri = uri;

			colon = uri.str(":");

			if (colon != null) {
				bool invalid_scheme = false;

				for (char* c = (char*) urip; c < colon; c++) {
					if (!((*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') || *c == '+' || *c == '-' || *c == '.')) {
						invalid_scheme = true;
						break;
					}
				}

				if (!invalid_scheme) {
					scheme = uri.substring(0, (long) (colon - urip));
					urip = colon + 1;
				}
			}

			if (scheme_uses_netloc (scheme) && urip->has_prefix("//")) {
				char* c = (char*) (urip + 2);
				while (*c != '\0' && *c != '/' && *c != '?' && *c != '#')
					c++;
				netloc = (urip + 2)->ndup(c - urip - 2);
				urip = c;
			} else {
				netloc = urip;
			}

			end = urip + urip->len();

			pound = urip->str("#");

			if (pound != null) {
				fragment = pound + 1;
				end = pound;
			}

			question = urip->str("?");

			if (question != null && (char*) question < (char*) end - 1) {
				query = ((string*) (question + 1))->ndup(end - question - 1);
				end = question;
			}

			return new Uri(full_uri, urip->ndup(end - urip), scheme, netloc, fragment, query);
		}

		public static string quote(string str, string? safe = null) {
			StringBuilder quoted = new StringBuilder();

			char* c = (char*) str;

			while (*c != '\0') {
				if ((*c).isalnum() || *c == '_' || *c == '.' || *c == '-' || (safe != null && strchr(safe, *c) != null)) {
					quoted.append_c(*c);
				} else {
					quoted.append_printf("%%%02X", *c);
				}
				c++;
			}

			return quoted.str;
		}

		public static string quote_query(string query) {
			if (strchr(query, ' ') != null) {
				string s = quote(query, " ");
				char* c = (char*) s;
				while (*c != '\0') {
					if (*c == ' ')
						*c = '+';
					c++;
				}
				return s;
			} else
				return quote(query, null);
		}
	}
}
