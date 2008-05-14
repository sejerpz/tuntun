/*
 * unix-socket.vapi part of snul
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

[CCode (cheader_filename="sys/socket.h")]
namespace UnixSocket
{
	[CCode (chader_filename="sys/types", cprefix = "AF_")]
	public enum AddressFamilies
	{
		INET
	}

        [CCode (cprefix = "SOCK_")]
	public enum SocketTypes
	{
		STREAM = 1,
		DGRAM = 2,
		RAW = 3
	}

	[CCode (cheader_filename = "netinet/in.h", cname = "struct sockaddr", free_function="free")]
        public class sockaddr
        {
                public ushort sa_family;
                public char[] sa_data = new char[14];
        }

	[CCode (cname = "struct in_addr")]
	public struct in_addr
	{
		public uint32 s_addr;
	}

        [CCode (cname = "struct sockaddr_in",  free_function="free")]
	public class sockaddr_in
	{
		public ushort sin_family;
		public uint16 sin_port;                 /* Port number.  */
		public in_addr sin_addr;            /* Internet address.  */

		/* Pad to size of `struct sockaddr'.  */
		char[] sin_sero = new char[sizeof (sockaddr) - sizeof(ushort) -
                           sizeof (uint16) -
                           sizeof (in_addr)];

	}

	[CCode (cname = "htons")]
	public static ushort htons (ushort data);
	[CCode (cname = "connect")]
	public static int connect (int socket_fd, sockaddr address, uint len);
	[CCode (cname = "socket")]
	public static int socket (AddressFamilies socket_family, int type, int protocol);

        [CCode (cheader_filename="netdb.h", cname="struct servent", free_function="free")]
        public class servent
        {
                public string s_name;
                public string[] s_aliases;
                public int s_port;
                public string s_proto;
        }

        [CCode (cheader_filename="netdb.h", cname="getservbyname", cprefix="")]
        public weak servent getservbyname (string name, string protocol);

        [CCode (cheader_filename="netdb.h", cname="struct hostent")]
        public class hostent
        {
                public string h_name;
                public string[] h_aliases;
                public int h_addrtype;
                public int h_length;
                public string[] h_addr_list;
        }

        [CCode (cheader_filename="netdb.h", cname="gethostbyname")]
        public weak hostent gethostbyname (string name);
}

namespace Utils
{
	[CCode (cprefix="G_IO_FLAG_")]
	public enum IOFlags
	{
		APPEND = 1 << 0,
		NONBLOCK = 1 << 1,
		IS_READABLE = 1 << 2,	/* Read only flag */
		IS_WRITEABLE = 1 << 3,	/* Read only flag */
		IS_SEEKABLE = 1 << 4,	/* Read only flag */
		MASK = (1 << 5) - 1,
	}

	[CCode (cname="g_io_channel_set_encoding")]
        public static GLib.IOStatus io_channel_set_encoding (IOChannel channel, string? encoding) throws ConvertError;

	[CCode (cname="g_io_channel_set_flags")]
        public static GLib.IOStatus io_channel_set_flags (IOChannel channel, IOFlags flags) throws IOChannelError;

	public static delegate bool IOFunc (IOChannel source, IOCondition conditions, void *data);

	[CCode (cname="g_io_add_watch")]
	public static uint io_add_watch (IOChannel channel, IOCondition conditions, IOFunc func, void *data);

	[CCode (cname="close")]
	public static void close (int fd);
}
