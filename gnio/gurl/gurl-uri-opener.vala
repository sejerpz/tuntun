using GLib;

namespace Gurl {
	[Compact]
	private class OpenData {
		public AsyncReadyCallback callback;
		public Cancellable cancellable;
		public weak List<Handler> handler;
		public HttpRequest request;
		public weak List<Handler> current;
		public UriOpener opener;
		public HttpResponse? response;

		/* TODO: make these local variables to open_async once #537706 is fixed */
		public AsyncReadyCallback request_chain;
		public AsyncReadyCallback open_chain;

		public void open_async() {
			request_chain = (handler, result) => {
				HttpRequest? new_request;

				try {
					new_request = current.data.handle_request_finish(result);

					if (new_request != null) {
						// debug("request handler gave new request, using it");
					} else {
						current = current.next;

						if (current != null) {
							current.data.handle_request_async(request, cancellable, request_chain);
							return;
						} else {
							// debug("request handler chain end reached, using same request");
							new_request = request;
						}
					}
				} catch (Error ex) {
					// debug("request handler raised exception, not going to try again");
					g_simple_async_report_gerror_in_idle(opener, callback, ex);
					return;
				}

				current = this.handler;

				this.handler.data.handle_open_async(new_request, cancellable, open_chain);
			};

			open_chain = (handler, result) => {
				try {
					response = current.data.handle_open_finish(result);

					if (response != null) {
						// debug("open handler gave response, using it");
					} else {
						current = current.next;

						if (current != null) {
							current.data.handle_open_async(request, cancellable, open_chain);
							return;
						} else {
							debug("request handler chain end reached with no response");
						}
					}
				} catch (Error ex) {
					// debug("open handler raised exception, not going to try again");
					g_simple_async_report_gerror_in_idle(opener, callback, ex);
					return;
				}

				SimpleAsyncResult simple = new SimpleAsyncResult(opener, callback, (void*) UriOpener.open_async);
				simple.set_op_res_gpointer((void*) this, delete_open_data);
				simple.complete_in_idle();
			};

			current = handler;

			handler.data.handle_request_async(request, cancellable, request_chain);
		}
	}

	private void delete_open_data(OpenData* data) {
		delete data;
	}

	public class UriOpener : Object {
		public void open_async(HttpRequest request, Cancellable? cancellable, AsyncReadyCallback callback) {
			OpenData* data = new OpenData();

			data->callback = callback;
			data->opener = this;
			data->cancellable = cancellable;
			data->handler = handlers;
			data->request = request;

			data->open_async();
		}

		public HttpResponse? open_finish(AsyncResult result) throws Error {
			SimpleAsyncResult simple = (SimpleAsyncResult) result;
			weak OpenData data;

			simple.propagate_error();

			if (simple.get_source_tag() != (void*) open_async)
				return null;

			data = (OpenData) simple.get_op_res_gpointer();

			return data.response;
		}

		public HttpResponse? open(HttpRequest request) throws Error {
			HttpRequest new_request;

			foreach (Handler handler in handlers) {
				try {
					new_request = handler.handle_request(request);
					if (new_request != null) {
						request = new_request;
						break;
					}
				} catch (Error ex) {
					debug("handler threw error handling request");
					throw ex;
				}
			}

			HttpResponse response;

			foreach (Handler handler in handlers) {
				try {
					response = handler.handle_open(request);
					if (response != null) {
						break;
					}
				} catch (Error ex) {
					debug("handler threw error handling open");
					throw ex;
				}
			}

			HttpResponse new_response;

			foreach (Handler handler in handlers) {
				try {
					new_response = handler.handle_response(response);
					if (new_response != null) {
						return new_response;
					}
				} catch (Error ex) {
					debug("handler threw error handling response");
					throw ex;
				}
			}

			return response;
		}

		public void set_as_default() {
			default_client = this;
		}

		public static HttpResponse? open_with_default(HttpRequest request) throws Error {
			if (default_client == null)
				error("A default GurlOpener must be registered before calling open_with_default");
			return default_client.open(request);
		}

		private static int loaded = 1;

		private static List<Handler> handlers;

		construct {
			if (AtomicInt.dec_and_test(ref loaded)) {
				IOExtensionPoint.register(EXTENSION_POINT_NAME).set_required_type(typeof(Handler));

				/* load all the modules from ${GIO_MODULE_DIR}/gurl/ for now */
				g_io_modules_load_all_in_directory(Config.GURL_MODULE_DIR);

				weak IOExtensionPoint ep = IOExtensionPoint.lookup(EXTENSION_POINT_NAME);

				foreach (weak IOExtension extension in (List<IOExtension>?) ep.get_extensions()) {
					debug("loading extension %s", extension.get_name());
					handlers.append((Handler) Object.new(extension.get_type()));
				}
			}
		}

		private static UriOpener? default_client;

		public static const string EXTENSION_POINT_NAME = "gurl-handler";
	}

	public class Handler : Object {
		public virtual HttpRequest? handle_request(HttpRequest request) throws UriError {
			return null;
		}

		public virtual void handle_request_async(HttpRequest request, Cancellable? cancellable, AsyncReadyCallback callback) {
			SimpleAsyncResult result = new SimpleAsyncResult(this, callback, (void*) handle_request_async);
			result.set_op_res_gpointer(null, null);
			result.complete_in_idle();
		}

		public virtual HttpRequest? handle_request_finish(AsyncResult result) throws Error {
			weak SimpleAsyncResult simple = (SimpleAsyncResult) result;
			simple.propagate_error();
			if (simple.get_source_tag() != (void*) handle_request_async)
				return null;
			return (HttpRequest?) simple.get_op_res_gpointer();
		}

		public virtual HttpResponse? handle_open(HttpRequest request) throws Error {
			return null;
		}

		private static void handle_open_thread(SimpleAsyncResult result, Object object, Cancellable? cancellable) {
			Handler handler = (Handler) object;
			HttpRequest request = (HttpRequest) result.get_op_res_gpointer();
			HttpResponse? response;
			try {
				response = handler.handle_open(request);
			} catch (Error ex) {
				result.set_from_error(ex);
				return;
			}
			if (response != null) {
				response.ref();
				result.set_op_res_gpointer((void*) response, g_object_unref);
			} else {
				result.set_op_res_gpointer(null, null);
			}
		}

		public virtual void handle_open_async(HttpRequest request, Cancellable? cancellable, AsyncReadyCallback callback) {
			SimpleAsyncResult result = new SimpleAsyncResult(this, callback, (void*) handle_open_async);
			result.set_op_res_gpointer(request, null);
			result.run_in_thread(handle_open_thread, 0, cancellable);
		}

		public virtual HttpResponse? handle_open_finish(AsyncResult result) throws Error {
			weak SimpleAsyncResult simple = (SimpleAsyncResult) result;
			simple.propagate_error();
			if (simple.get_source_tag() != (void*) handle_open_async)
				return null;;
			return (HttpResponse?) simple.get_op_res_gpointer();
		}

		public virtual HttpResponse? handle_response(HttpResponse response) throws UriError {
			return null;
		}
	}
}
