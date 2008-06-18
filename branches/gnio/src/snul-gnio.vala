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
		IOCHANNEL_NVAL
	}

	public class TcpClient : GLib.Object
	{

		public signal void connected (SocketConnection socket);
		public signal void data_received (string buffer, size_t len);
		public signal void disconnected ();
		public signal void error (Error error);

		private const string error_domain_quark = "tcp_socket_error_domain-quark";

		private string _address = null;
		private string _first_address = null;
		private string _port = null;
		private ushort _port_number = 0;

		private Resolver _resolver = null;
		private InetAddress _inet_address = null;
		private SocketConnection _client = null;
                private Source _source = null;
                private DataInputStream _input = null;

		public string address { get { return _address; } }
		public string first_address { get { return address; } set { _first_address = value; } }
		public string port { get { return _port; } }


		//[CCode (cname="g_source_set_callback")]
		//private static extern void source_set_callback (Source source, SourceFunc func, DestroyNotify? notify);

                construct
                {
                        
                }

                [CCode (instance_pos = 2.5)]
		private void on_address_resolved (Object sender, AsyncResult result)
		{
			try {
				_inet_address = ((Resolver) sender).resolve_finish (result);
				var socket_address = new InetSocketAddress (_inet_address, (ushort) _port.to_int ());
			        _client = new SocketConnection (socket_address);
				_client.connect_async (null, this.on_client_connected);

			} catch (Error err) {
				this.error (err);
			}
		}

                [CCode (instance_pos = 2.5)]
		private void on_client_connected (Object sender, AsyncResult result)
		{
			try {
				if (((SocketConnection) sender).connect_finish (result)) {
					// create a source for
					// monitoring incoming data
                                        _client = (SocketConnection) sender;
                                        _input = new DataInputStream (_client.input_stream);
					IOCondition conditions = IOCondition.IN | IOCondition.HUP | IOCondition.ERR | IOCondition.NVAL;
					_source = _client.input_stream.socket.create_source (conditions, null);
                                        Extensions.source_set_callback (_source, (void*) socket_callback, this, null);
                                        _source.attach (null);
					this.connected (_client);
				}
			} catch (Error err) {
				this.on_error (err);
			}
		}
	    
		public void connect (string address, string port) throws TcpSocketError
		{
			try {
				if (_client != null)
					throw new TcpSocketError.SOCKET_ALREADY_OPEN ("Socket already opened");

				this._address = address;
				this._port = port;

				_resolver = new Resolver();
				_resolver.resolve_async (this._address, null, this.on_address_resolved);
			} catch (GLib.Error err) {
				this.on_error (err);
				throw err;
			}
		}

		public size_t send (string buffer)
		{
			size_t bytes_written = 0;

			try {
                                _client.output_stream.write (buffer, buffer.len (), null);
			} catch (Error err) {
				warning ("error writing: %s", err.message);
                                this.on_error (err);
			}

			return bytes_written;
		}

		public void disconnect ()
		{
			if (_source != null) {
				_source.destroy ();
				_source = null;
			}

			if (_client != null) {
                                _input = null;
				_client.close ();
				_client = null;
			}

			on_disconnected ();
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


		private bool socket_callback (IOCondition condition, int fd)
		{
			bool res = true;

			switch (condition) {
				case IOCondition.IN:
					size_t length = 0;

                                        string message = _input.read_line (out length, null);
                                        if (message != null)
                                                message = message.strip ();

                                        if (length > 0) {
                                                this.on_data_received (message, length);
                                        } else {
                                                this.on_error (new TcpSocketError.SOCKET_BROKEN ("zero length data, socket broken? Closing connection."));
                                                this.disconnect ();
                                        }

					break;
				case IOCondition.HUP:
                                        critical ("HUP");
                                        this.on_error (new TcpSocketError.SOCKET_HUP ("Socket HUP")); // new Error (Quark.from_string (error_domain_quark), 0, "IOChannel error (HUP)"));
					this.disconnect ();
					res = false;
					break;
				case IOCondition.ERR:
                                        critical ("ERR");
					this.on_error (new TcpSocketError.IOCHANNEL_ERROR ("IOChannel error (ERR)"));
					this.disconnect ();
					break;
				case IOCondition.NVAL:
                                        critical ("NVAL");
					this.on_error (new TcpSocketError.IOCHANNEL_NVAL ("IOChannel invalid request (NAVL)"));
					this.disconnect ();
					break;
			}
			return res;
		}

	}
}
