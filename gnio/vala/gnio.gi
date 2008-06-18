<?xml version="1.0"?>
<api version="1.0">
	<namespace name="GLib">
		<enum name="GSocketDomain" type-name="GSocketDomain" get-type="g_socket_domain_get_type">
			<member name="G_SOCKET_DOMAIN_INET" value="0"/>
			<member name="G_SOCKET_DOMAIN_INET6" value="1"/>
			<member name="G_SOCKET_DOMAIN_LOCAL" value="2"/>
		</enum>
		<enum name="GSocketType" type-name="GSocketType" get-type="g_socket_type_get_type">
			<member name="G_SOCKET_TYPE_STREAM" value="0"/>
			<member name="G_SOCKET_TYPE_DATAGRAM" value="1"/>
			<member name="G_SOCKET_TYPE_SEQPACKET" value="2"/>
		</enum>
		<object name="GInet4Address" parent="GInetAddress" type-name="GInet4Address" get-type="g_inet4_address_get_type">
			<method name="from_bytes" symbol="g_inet4_address_from_bytes">
				<return-type type="GInet4Address*"/>
				<parameters>
					<parameter name="bytes" type="guint8[]"/>
				</parameters>
			</method>
			<method name="from_string" symbol="g_inet4_address_from_string">
				<return-type type="GInet4Address*"/>
				<parameters>
					<parameter name="string" type="char*"/>
				</parameters>
			</method>
			<constructor name="new_any" symbol="g_inet4_address_new_any">
				<return-type type="GInet4Address*"/>
			</constructor>
			<constructor name="new_loopback" symbol="g_inet4_address_new_loopback">
				<return-type type="GInet4Address*"/>
			</constructor>
			<method name="to_bytes" symbol="g_inet4_address_to_bytes">
				<return-type type="guint8*"/>
				<parameters>
					<parameter name="address" type="GInet4Address*"/>
				</parameters>
			</method>
		</object>
		<object name="GInet6Address" parent="GInetAddress" type-name="GInet6Address" get-type="g_inet6_address_get_type">
			<method name="from_bytes" symbol="g_inet6_address_from_bytes">
				<return-type type="GInet6Address*"/>
				<parameters>
					<parameter name="bytes" type="guint8[]"/>
				</parameters>
			</method>
			<method name="from_string" symbol="g_inet6_address_from_string">
				<return-type type="GInet6Address*"/>
				<parameters>
					<parameter name="string" type="char*"/>
				</parameters>
			</method>
			<constructor name="new_any" symbol="g_inet6_address_new_any">
				<return-type type="GInet6Address*"/>
			</constructor>
			<constructor name="new_loopback" symbol="g_inet6_address_new_loopback">
				<return-type type="GInet6Address*"/>
			</constructor>
			<method name="to_bytes" symbol="g_inet6_address_to_bytes">
				<return-type type="guint8*"/>
				<parameters>
					<parameter name="address" type="GInet6Address*"/>
				</parameters>
			</method>
		</object>
		<object name="GInetAddress" parent="GInitiallyUnowned" type-name="GInetAddress" get-type="g_inet_address_get_type">
			<method name="is_any" symbol="g_inet_address_is_any">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_link_local" symbol="g_inet_address_is_link_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_loopback" symbol="g_inet_address_is_loopback">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_mc_global" symbol="g_inet_address_is_mc_global">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_mc_link_local" symbol="g_inet_address_is_mc_link_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_mc_node_local" symbol="g_inet_address_is_mc_node_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_mc_org_local" symbol="g_inet_address_is_mc_org_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_mc_site_local" symbol="g_inet_address_is_mc_site_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_multicast" symbol="g_inet_address_is_multicast">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="is_site_local" symbol="g_inet_address_is_site_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<method name="to_string" symbol="g_inet_address_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</method>
			<property name="is-any" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-link-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-loopback" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-mc-global" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-mc-link-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-mc-node-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-mc-org-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-mc-site-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-multicast" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="is-site-local" type="gboolean" readable="1" writable="0" construct="0" construct-only="0"/>
			<vfunc name="to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="GInetSocketAddress" parent="GSocketAddress" type-name="GInetSocketAddress" get-type="g_inet_socket_address_get_type">
			<method name="get_address" symbol="g_inet_socket_address_get_address">
				<return-type type="GInetAddress*"/>
				<parameters>
					<parameter name="address" type="GInetSocketAddress*"/>
				</parameters>
			</method>
			<method name="get_port" symbol="g_inet_socket_address_get_port">
				<return-type type="guint16"/>
				<parameters>
					<parameter name="address" type="GInetSocketAddress*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="g_inet_socket_address_new">
				<return-type type="GInetSocketAddress*"/>
				<parameters>
					<parameter name="address" type="GInetAddress*"/>
					<parameter name="port" type="guint16"/>
				</parameters>
			</constructor>
			<property name="address" type="GInetAddress*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="port" type="guint" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GResolver" parent="GObject" type-name="GResolver" get-type="g_resolver_get_type">
			<constructor name="new" symbol="g_resolver_new">
				<return-type type="GResolver*"/>
			</constructor>
			<method name="resolve" symbol="g_resolver_resolve">
				<return-type type="GInetAddress*"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="host" type="char*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="resolve_async" symbol="g_resolver_resolve_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="host" type="char*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="resolve_finish" symbol="g_resolver_resolve_finish">
				<return-type type="GInetAddress*"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="resolve_list" symbol="g_resolver_resolve_list">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="host" type="char*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="resolve_list_async" symbol="g_resolver_resolve_list_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="host" type="char*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="resolve_list_finish" symbol="g_resolver_resolve_list_finish">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="resolver" type="GResolver*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
		</object>
		<object name="GSocket" parent="GObject" type-name="GSocket" get-type="g_socket_get_type">
			<method name="accept" symbol="g_socket_accept">
				<return-type type="GSocket*"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="bind" symbol="g_socket_bind">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="address" type="GSocketAddress*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="close" symbol="g_socket_close">
				<return-type type="void"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
				</parameters>
			</method>
			<method name="connect" symbol="g_socket_connect">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="address" type="GSocketAddress*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="create_source" symbol="g_socket_create_source">
				<return-type type="GSource*"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="condition" type="GIOCondition"/>
					<parameter name="cancellable" type="GCancellable*"/>
				</parameters>
			</method>
			<method name="get_blocking" symbol="g_socket_get_blocking">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
				</parameters>
			</method>
			<method name="get_local_address" symbol="g_socket_get_local_address">
				<return-type type="GSocketAddress*"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_remote_address" symbol="g_socket_get_remote_address">
				<return-type type="GSocketAddress*"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_reuse_address" symbol="g_socket_get_reuse_address">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
				</parameters>
			</method>
			<method name="has_error" symbol="g_socket_has_error">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="listen" symbol="g_socket_listen">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<constructor name="new" symbol="g_socket_new">
				<return-type type="GSocket*"/>
				<parameters>
					<parameter name="domain" type="GSocketDomain"/>
					<parameter name="type" type="GSocketType"/>
					<parameter name="protocol" type="gchar*"/>
				</parameters>
			</constructor>
			<constructor name="new_from_fd" symbol="g_socket_new_from_fd">
				<return-type type="GSocket*"/>
				<parameters>
					<parameter name="fd" type="gint"/>
				</parameters>
			</constructor>
			<method name="receive" symbol="g_socket_receive">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="buffer" type="gchar*"/>
					<parameter name="size" type="gsize"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="send" symbol="g_socket_send">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="buffer" type="gchar*"/>
					<parameter name="size" type="gsize"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="set_blocking" symbol="g_socket_set_blocking">
				<return-type type="void"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="blocking" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_reuse_address" symbol="g_socket_set_reuse_address">
				<return-type type="void"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
					<parameter name="reuse" type="gboolean"/>
				</parameters>
			</method>
			<property name="backlog" type="gint" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="blocking" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="domain" type="GSocketDomain" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="fd" type="gint" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="local-address" type="GSocketAddress*" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="protocol" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="remote-address" type="GSocketAddress*" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="reuse-address" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="type" type="GSocketType" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GSocketAddress" parent="GInitiallyUnowned" type-name="GSocketAddress" get-type="g_socket_address_get_type">
			<method name="from_native" symbol="g_socket_address_from_native">
				<return-type type="GSocketAddress*"/>
				<parameters>
					<parameter name="native" type="gpointer"/>
					<parameter name="len" type="gsize"/>
				</parameters>
			</method>
			<method name="native_size" symbol="g_socket_address_native_size">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
				</parameters>
			</method>
			<method name="to_native" symbol="g_socket_address_to_native">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
					<parameter name="dest" type="gpointer"/>
				</parameters>
			</method>
			<vfunc name="native_size">
				<return-type type="gssize"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
				</parameters>
			</vfunc>
			<vfunc name="to_native">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
					<parameter name="dest" type="gpointer"/>
				</parameters>
			</vfunc>
		</object>
		<object name="GSocketConnection" parent="GObject" type-name="GSocketConnection" get-type="g_socket_connection_get_type">
			<method name="close" symbol="g_socket_connection_close">
				<return-type type="void"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</method>
			<method name="connect" symbol="g_socket_connection_connect">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="connect_async" symbol="g_socket_connection_connect_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="connect_finish" symbol="g_socket_connection_connect_finish">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="get_address" symbol="g_socket_connection_get_address">
				<return-type type="GSocketAddress*"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</method>
			<method name="get_input_stream" symbol="g_socket_connection_get_input_stream">
				<return-type type="GSocketInputStream*"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</method>
			<method name="get_output_stream" symbol="g_socket_connection_get_output_stream">
				<return-type type="GSocketOutputStream*"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="g_socket_connection_new">
				<return-type type="GSocketConnection*"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
				</parameters>
			</constructor>
			<constructor name="new_from_socket" symbol="g_socket_connection_new_from_socket">
				<return-type type="GSocketConnection*"/>
				<parameters>
					<parameter name="socket" type="GSocket*"/>
				</parameters>
			</constructor>
			<property name="address" type="GSocketAddress*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="input-stream" type="GSocketInputStream*" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="output-stream" type="GSocketOutputStream*" readable="1" writable="0" construct="0" construct-only="0"/>
			<property name="socket" type="GSocket*" readable="1" writable="1" construct="0" construct-only="1"/>
			<vfunc name="connect_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</vfunc>
			<vfunc name="connect_finish">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</vfunc>
			<vfunc name="connect_fn">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</vfunc>
			<vfunc name="get_input_stream">
				<return-type type="GSocketInputStream*"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_output_stream">
				<return-type type="GSocketOutputStream*"/>
				<parameters>
					<parameter name="connection" type="GSocketConnection*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="GSocketInputStream" parent="GInputStream" type-name="GSocketInputStream" get-type="g_socket_input_stream_get_type">
			<property name="socket" type="GSocket*" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GSocketOutputStream" parent="GOutputStream" type-name="GSocketOutputStream" get-type="g_socket_output_stream_get_type">
			<property name="socket" type="GSocket*" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GSocketServer" parent="GObject" type-name="GSocketServer" get-type="g_socket_server_get_type">
			<method name="accept" symbol="g_socket_server_accept">
				<return-type type="GSocketConnection*"/>
				<parameters>
					<parameter name="server" type="GSocketServer*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="accept_async" symbol="g_socket_server_accept_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="server" type="GSocketServer*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="accept_finish" symbol="g_socket_server_accept_finish">
				<return-type type="GSocketConnection*"/>
				<parameters>
					<parameter name="server" type="GSocketServer*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="close" symbol="g_socket_server_close">
				<return-type type="void"/>
				<parameters>
					<parameter name="server" type="GSocketServer*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="g_socket_server_new">
				<return-type type="GSocketServer*"/>
				<parameters>
					<parameter name="address" type="GSocketAddress*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</constructor>
			<property name="address" type="GSocketAddress*" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GTCPConnection" parent="GSocketConnection" type-name="GTCPConnection" get-type="g_tcp_connection_get_type">
			<constructor name="new" symbol="g_tcp_connection_new">
				<return-type type="GTCPConnection*"/>
				<parameters>
					<parameter name="hostname" type="gchar*"/>
					<parameter name="port" type="gushort"/>
				</parameters>
			</constructor>
			<property name="address" type="GInetSocketAddress*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="hostname" type="char*" readable="1" writable="1" construct="0" construct-only="1"/>
			<property name="port" type="guint" readable="1" writable="1" construct="0" construct-only="1"/>
		</object>
		<object name="GTCPServer" parent="GSocketServer" type-name="GTCPServer" get-type="g_tcp_server_get_type">
			<method name="accept" symbol="g_tcp_server_accept">
				<return-type type="GTCPConnection*"/>
				<parameters>
					<parameter name="server" type="GTCPServer*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="accept_async" symbol="g_tcp_server_accept_async">
				<return-type type="void"/>
				<parameters>
					<parameter name="server" type="GTCPServer*"/>
					<parameter name="cancellable" type="GCancellable*"/>
					<parameter name="callback" type="GAsyncReadyCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="accept_finish" symbol="g_tcp_server_accept_finish">
				<return-type type="GTCPConnection*"/>
				<parameters>
					<parameter name="server" type="GTCPServer*"/>
					<parameter name="result" type="GAsyncResult*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</method>
			<method name="close" symbol="g_tcp_server_close">
				<return-type type="void"/>
				<parameters>
					<parameter name="server" type="GTCPServer*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="g_tcp_server_new">
				<return-type type="GTCPServer*"/>
				<parameters>
					<parameter name="address" type="GInetSocketAddress*"/>
					<parameter name="error" type="GError**"/>
				</parameters>
			</constructor>
		</object>
		<constant name="G_IO_ERROR_ADDRESS_IN_USE" type="int" value="33"/>
		<constant name="G_IO_ERROR_RESOLVER_NOT_FOUND" type="int" value="31"/>
		<constant name="G_IO_ERROR_RESOLVER_NO_DATA" type="int" value="32"/>
	</namespace>
</api>
