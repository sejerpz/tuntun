/*
 * based on: snul.vala (part of Snul)
 *
 * Snul: is a simple library that implements
 *       a tcp socket client in vala
 *
 * Copyright (C) 2008  Andrea Del Signore
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 *
 * Author:
 *     Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;

namespace Snul
{
	public errordomain TcpSocketError
	{
                LOOKUP_SERVICE_FAILED,
                LOOKUP_HOSTNAME_FAILED,
                SOCKET_CREATION_ERROR,
                SOCKET_CONNECT_ERROR,
                SOCKET_ALREADY_OPEN,
		SOCKET_CLOSED,
		SOCKET_BROKEN,
		SOCKET_HUP,
		IOCHANNEL_ERROR,
	        IOCHANNEL_NVAL,
		OPERATION_TIMEOUT
	}

	public class TcpClient : GLib.Object
	{

		public signal void connected (SocketConnection socket);
		public signal void data_received (string buffer, size_t len);
		public signal void disconnected ();
		public signal void error (Error error);

		private string _address = null;
		private string _first_address = null;
		private string _port = null;

		private Resolver _resolver = null;
		private InetAddress _inet_address = null;
		private SocketClient _client = null;
		private SocketConnection _connection = null;
		private IOChannel _in_channel = null;
                private Source _source = null;
                private uint _source_id = 0;
                private DataInputStream _input = null;
		private Cancellable _cancellable = null;
		private uint _timeout_id = 0;
		private const int TimeoutValue = 10; // timeout in seconds

		public string address { get { return _address; } }
		public string first_address { get { return address; } set { _first_address = value; } }
		public string port { get { return _port; } }

		~TcpClient ()
		{
			cleanup ();
		}

		public async new void connect (string address, string port) throws Error
		{
			try {
				if (_client != null)
					throw new TcpSocketError.SOCKET_ALREADY_OPEN ("Socket already opened");

				this._address = address;
				this._port = port;
				this._cancellable = new Cancellable ();

				_timeout_id = Timeout.add_seconds (TimeoutValue, this.on_operation_timed_out);
				_resolver = Resolver.get_default();
				unowned List<InetAddress> results = yield _resolver.lookup_by_name_async (this._address, this._cancellable);
				
				if (results != null) {
					_inet_address = (InetAddress) results.nth_data (0);
					var socket_address = new InetSocketAddress (_inet_address, (ushort) _port.to_int ());
					_client = new SocketClient ();
					_connection = yield _client.connect_async (socket_address, this._cancellable);

					// connected. create a source for monitoring incoming data
					this._cancellable = null;
					_connection.get_socket().set_blocking (false);
					_input = new DataInputStream (_connection.get_input_stream());
					IOCondition conditions = IOCondition.IN | IOCondition.HUP | IOCondition.ERR | IOCondition.NVAL;
					_in_channel = new IOChannel.unix_new (_connection.get_socket().get_fd());
					_source_id = _in_channel.add_watch (conditions, this.socket_callback);
				
					//_source = _client.input_stream.socket.create_source (conditions, null);
					//Extensions.source_set_callback (_source, (void*) socket_callback, this, null);
					//_source.attach (null);
					this.connected (_connection);
					
					if (_timeout_id != 0) {
						Source.remove (_timeout_id);
						_timeout_id = 0;
					}
				}
				
			} catch (GLib.Error err) {
				this.on_error (err);
				throw err;
			}
		}

		private bool on_operation_timed_out ()
		{
			if (_cancellable != null && !_cancellable.is_cancelled ()) {
				_cancellable.cancel ();
				this.on_error (new TcpSocketError.OPERATION_TIMEOUT ("Operation timeout"));
			}
			_timeout_id = 0;
			return false;
		}

		public size_t send (string buffer)
		{
			size_t bytes_written = 0;

			try {
                                _connection.output_stream.write (buffer, buffer.len (), null);
			} catch (Error err) {
				warning ("error writing: %s", err.message);
                                this.on_error (err);
			}

			return bytes_written;
		}

		public void disconnect ()
		{
			cleanup ();
			on_disconnected ();
		}

		private void cleanup ()
		{
			try {
				
				Source.remove_by_user_data (this);

				if (_source_id != 0) {
					Source.remove (_source_id);
					_source_id = 0;
				}
			
				if (_source != null) {
					_source.destroy ();
					_source = null;
				}

				if (_connection != null) {
					_input = null;
					_in_channel = null;
					_connection.close (null);
					_connection = null;
				}
				if (_client != null) {
					_client = null;
				}
			} catch (Error err) {
				warning ("error cleanup: %s", err.message);
                                this.on_error (err);
			}
		}

		protected virtual void on_connected (SocketConnection client)
		{
			connected (client);
		}

		protected virtual void on_data_received (string buffer, size_t len)
		{
			data_received (buffer, len);
		}

		protected virtual void on_disconnected ()
		{
			disconnected ();
		}

		protected virtual void on_error (Error error)
		{
			this.error (error);
		}


		private bool socket_callback (IOChannel source, IOCondition condition)
		{
			bool res = true;

			switch (condition) {
				case IOCondition.IN:
					size_t length = -1;
					
                                        var message = new StringBuilder ();

					//HACK: this makes me sure
					//that I empty the socket buffer
					while (length != 0) {
						try {
							string buffer = _input.read_line (out length, null);
							if (buffer != null) {
								message.append_printf ("%s\n", buffer);
							}
						} catch (IOError err) {
                                                        if (err.code != 27) { //IOError.WOULD_BLOCK
                                                                this.on_error (err);
                                                        }
							length = 0;
						}
					}

                                        if (message.len > 0) {
                                                this.on_data_received (message.str, message.len);
                                        } else {
                                                this.on_error (new TcpSocketError.SOCKET_BROKEN ("zero length data, socket broken? Closing connection."));
                                                this.disconnect ();
                                        }

					break;
				case IOCondition.HUP:
                                        this.on_error (new TcpSocketError.SOCKET_HUP ("Socket HUP"));
					this.disconnect ();
					res = false;
					break;
				case IOCondition.ERR:
					this.on_error (new TcpSocketError.IOCHANNEL_ERROR ("IOChannel error (ERR)"));
					this.disconnect ();
					break;
				case IOCondition.NVAL:
					this.on_error (new TcpSocketError.IOCHANNEL_NVAL ("IOChannel invalid request (NAVL)"));
					this.disconnect ();
					break;
			}
			return res;
		}

	}
}
