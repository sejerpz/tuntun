/*
 * snul.vala is a part of Snul
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
using UnixSocket;

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

		public signal void connected (int socket_fd);
		public signal void data_received (string buffer, size_t len);
		public signal void disconnected ();
		public signal void error (Error error);

		private const string error_domain_quark = "tcp_socket_error_domain-quark";

		private string _address = null;
		private string _first_address = null;
		private string _port = null;
		private ushort _port_number = 0;
		private int _socket_fd = 0;

		private IOChannel _io_channel = null;
		private uint _watch_id = 0;
		private uint _resolver_watch_id = 0;
		private bool _resolving_address = false;
		private bool _resolv_timeout = 30;
		private	weak hostent hp = null;
		private static int BUFFER_LENGTH = 1024;
		private static char[] _io_channel_buffer = new char[BUFFER_LENGTH];

		public string address { get { return _address; } }
		public string first_address { get { return address; } set { _first_address = value; } }
		public string port { get { return _port; } }

		private bool resolv_watcher ()
		{
			if (_resolving_address) 
				return true;

			this.connect_second_phase ();

			_resolver_watch_id = 0;
			return false;
		}

		private void* resolv_thread () 
		{
			_resolving_address = true;
			_resolver_watch_id = Timeout.add (250, this.resolv_watcher);
			hp = gethostbyname (_address);
			if (hp == null) {
				_first_address = null;
			} else {
				_first_address = "%s".printf(hp.h_addr_list[0]);
			}
			_resolving_address = false;
			return null;
		}

		private void resolv (string address)
		{
			try {
				Thread.create (this.resolv_thread, false);
			} catch (ThreadError err) {
				warning ("resolv error %d: %s", err.code, err.message);
			}
		}

		public void connect (string address, string port) throws TcpSocketError
		{
			try {
				this._address = address;
				this._port = port;

				if (_socket_fd > 0)
					throw new TcpSocketError.SOCKET_ALREADY_OPEN ("Socket already opened");

				if (_port[0].isdigit()) {
					_port_number = (ushort) _port.to_int();
				} else {
					weak servent sp = getservbyname (_port, "tcp");
					if (sp == null) {
						throw new TcpSocketError.LOOKUP_SERVICE_FAILED ("Lookup service by name failed");
					}
					_port_number = (ushort) sp.s_port;
				}

				this.resolv (address);
			} catch (GLib.Error err) {
				on_error ((Error) err);
				throw err;
			}
		}


		private void connect_second_phase ()
		{
			try {
				if (hp == null) {
					throw new TcpSocketError.LOOKUP_HOSTNAME_FAILED ("Resolv failed: hostname not found");
				}

				_socket_fd = socket (AddressFamilies.INET, SocketTypes.STREAM, 0);
				if (_socket_fd < 0) {
					throw new TcpSocketError.SOCKET_CREATION_ERROR ("Socket creation failed");
				}

				sockaddr_in sin = new sockaddr_in ();
				in_addr *add = hp.h_addr_list[0];
				sin.sin_family = AddressFamilies.INET;
				sin.sin_addr.s_addr = add->s_addr;
				sin.sin_port = UnixSocket.htons(_port_number);
				
				if (UnixSocket.connect ( _socket_fd, (sockaddr) sin, (uint) sizeof (sockaddr)) < 0) {
					throw new TcpSocketError.SOCKET_CONNECT_ERROR ("Connect error");
				}

				if (_socket_fd <= 0)
					throw new TcpSocketError.SOCKET_CLOSED ("Closed or bad socket");

				_io_channel = new IOChannel.unix_new (_socket_fd);
				try {
					Utils.io_channel_set_encoding (_io_channel, null);
					Utils.io_channel_set_flags (_io_channel, Utils.IOFlags.APPEND | Utils.IOFlags.NONBLOCK);
				} catch (ConvertError err) {
					throw err;
				}

				IOCondition conditions = IOCondition.IN | IOCondition.HUP | IOCondition.ERR | IOCondition.NVAL;
				_watch_id = Utils.io_add_watch (_io_channel, conditions, this.socket_callback, this);

				on_connected (_socket_fd);
			} catch (GLib.Error err) {
				on_error ((Error) err);
			}
		}

		public size_t send (string buffer)
		{
			if (buffer == null)
				return 0;

			ssize_t len = buffer.size ();
			size_t bytes_written;

			try {
				_io_channel.write_chars ((char[])buffer, (ssize_t) len, out bytes_written);
				_io_channel.flush ();
			} catch (Error err) {
				warning ("error writing: %s", err.message);
			}
			return bytes_written;
		}

		public void disconnect ()
		{
			if (_watch_id != 0) {
				Source.remove (_watch_id);
				_watch_id = 0;
			}

			if (_io_channel != null) {
				try {
					_io_channel.shutdown (false);
				} catch (Error err) {
					warning ("error shutting down channel: %s", err.message);
				}
				_io_channel = null;
			}

			if (_socket_fd != 0)
                                Utils.close (_socket_fd);

			on_disconnected ();
		}

		protected void on_connected (int socket_fd)
		{
			connected (socket_fd);
		}

		protected void on_data_received (string buffer, size_t len)
		{
			data_received (buffer, len);
		}

		protected void on_disconnected ()
		{
			disconnected ();
		}

		protected void on_error (Error error)
		{
			this.error (error);
		}

               
		private void on_connected_real () throws TcpSocketError, ConvertError
		{
		}

		static bool socket_callback (IOChannel channel, IOCondition condition, pointer data)
		{
			var client = (TcpClient) data;
			bool res = true;

			switch (condition) {
				case IOCondition.IN:
					size_t bytes_read = 0;

					try {
						channel.read_chars (_io_channel_buffer, BUFFER_LENGTH - 1, out bytes_read);
						//null terminate
						_io_channel_buffer[bytes_read] = (char) null;
						if (bytes_read > 0) {
							client.on_data_received ((string)_io_channel_buffer, bytes_read);
						} else {
							client.on_error (new TcpSocketError.SOCKET_BROKEN ("zero length data, socket broken? Closing connection."));
							client.disconnect ();
						}
					} catch (Error err) {
						warning ("error reading: %s", err.message);
					}
					break;
				case IOCondition.HUP:
                                        client.on_error (new TcpSocketError.SOCKET_HUP ("Socket HUP")); // new Error (Quark.from_string (error_domain_quark), 0, "IOChannel error (HUP)"));
					client.disconnect ();
					res = false;
					break;
				case IOCondition.ERR:
					client.on_error (new TcpSocketError.IOCHANNEL_ERROR ("IOChannel error (ERR)"));
					client.disconnect ();
					break;
				case IOCondition.NVAL:
					client.on_error (new TcpSocketError.IOCHANNEL_NVAL ("IOChannel invalid request (NAVL)"));
					client.disconnect ();
					break;
			}
			return res;
		}

	}
}
