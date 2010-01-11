using GLib;
using Snul;

namespace Tuntun {
	public enum ConnectionStates 
	{
		UNKNOWN = 0,
		ERROR = 1,
		CONNECTED = 2,
		CONNECTING = 3,
		DISCONNECTED = 4,
		DISCONNECTING = 5
	}

	public enum AuthenticationModes
	{
		PASSWORD_ONLY,
		USERNAME_PASSWORD
	}

	private enum AuthenticationSteps
	{
		NONE,
		USERNAME,
		PASSWORD,
	}

	public class Connection : Object {
		public signal void control_channel_data_received (string data);
		public signal void control_channel_data_sent (string data);
		public signal void control_channel_fatal_error (string error);
		public signal void authentication_required (AuthenticationModes mode, string type);
		public signal void authentication_failed (AuthenticationModes mode, string type);

		private ConnectionInfo _info;
		private ConnectionStates _status;
		private ConnectionStates _control_channel_status;
		private TcpClient _client;

		private bool _status_requested = false;
		private bool _suspend_notifications = false;
		private bool _suppress_auth_failed = false;

		private string _auth_type = null;
		private string _auth_username = null;
		private string _auth_password = null;
		private AuthenticationSteps _auth_step = AuthenticationSteps.NONE;

		public Connection (ConnectionInfo info) 
		{
			Object(info: info);
		}
		
		public weak ConnectionInfo info 
		{
			get { return _info; }
			construct 
			{ 
				_info = value; 
			}
		}

		public ConnectionStates control_channel_status
		{
			get { return _control_channel_status; }
			set {
				if (_control_channel_status != value) {
					_control_channel_status = value;
					if (!_suspend_notifications) {
						notify ("control-channel-status");
					}
				}
			}
		}

		public ConnectionStates status 
		{
			get { return _status; }
			set
			{
				if (_status != value) {
					_status = value;
					if (_status != ConnectionStates.CONNECTED && 
					    _info.assigned_ip != _("none")) {
						_info.assigned_ip = _("none");
					}
					if (!_suspend_notifications)
						notify ("status");
				}
			}
		}

		private new void notify (string property_name)
		{
			Extensions.notify_property_changed (this, property_name);
		}

		construct 
		{
			_status = ConnectionStates.UNKNOWN;
		}

		
		public bool initialize ()
		{
			_client = new TcpClient ();
			_client.connected += this.client_connected;
			_client.data_received += this.client_data_received;
			_client.disconnected += this.client_disconnected;
			_client.error += this.client_error;

			return control_channel_connect ();
		}

		private bool control_channel_connect ()
		{
			_suspend_notifications = true;
			_status_requested = false;
			try {

				this.control_channel_status = ConnectionStates.CONNECTING;
				_client.connect (_info.address, _info.port.to_string() );
				return true;
			} catch (Error err) {
				warning ("Error initializiong connection %s", err.message);
				this.control_channel_status = ConnectionStates.ERROR;
				return false;
			}
		}

		public bool reinitialize ()
		{
			if (this.status == ConnectionStates.CONNECTED)
				_client.disconnect ();

			return initialize ();
		}

		private void client_connected (TcpClient sender, SocketConnection socket)
		{
			this.control_channel_status = ConnectionStates.CONNECTED;
                        _client.send ("state on\n");

			if (this._control_channel_status != ConnectionStates.ERROR) {
				_status_requested = true;
				_client.send ("state\n");
			}
		}

		private void client_disconnected (TcpClient sender)
		{
			if (this.status != ConnectionStates.ERROR)
				this.status = ConnectionStates.UNKNOWN;
		}

		private void client_error (TcpClient sender, GLib.Error error)
		{
			_suspend_notifications = false;
			//disconnect immediatly, if not everything explodes
			sender.disconnect ();
			this.control_channel_status = ConnectionStates.ERROR;
			_status_requested = false;
		}

		private void client_data_received (TcpClient sender, string buffer, size_t len)
		{
			string[] lines = buffer.split ("\n");
			foreach(string line in lines) {
				if (line == "" || line == "\n")
					continue;

				if (_status_requested && PatternSpec.match_simple("*,CONNECTED,SUCCESS,*", line)) {
					this.status = ConnectionStates.CONNECTED;
					this._info.assigned_ip = extract_ip_address (line);
					this._status_requested = false;
					_suspend_notifications = false;
				} else if (_status_requested && 
				    (PatternSpec.match_simple("*,RECONNECTING,*", line) ||
					PatternSpec.match_simple("*,CONNECTING,*", line))) {
					this.status = ConnectionStates.DISCONNECTED;
					this._status_requested = false;
					_suspend_notifications = false;
				} else if (PatternSpec.match_simple(">STATE:*,CONNECTED,SUCCESS,*", line))
					this.status = ConnectionStates.CONNECTED;
				else if (PatternSpec.match_simple(">STATE:*,RECONNECTING,*error*", line) ||
				    PatternSpec.match_simple(">STATE:*,RECONNECTING,SIGHUP*", line)) {
					this.status = ConnectionStates.DISCONNECTED;
				} else if (PatternSpec.match_simple(">STATE:*,RECONNECTING,auth-failure*", line) ||
					 PatternSpec.match_simple(">STATE:*,RECONNECTING,private-key-password-failure*", line))
					/* no status changed event */
					this._status = ConnectionStates.DISCONNECTED;
				else if (PatternSpec.match_simple(">STATE:*,WAIT", line))
					this.status = ConnectionStates.CONNECTING;
				else if (PatternSpec.match_simple (">PASSWORD*'Auth'*username/password*", line)) {
					this.authentication_required (AuthenticationModes.USERNAME_PASSWORD, "Auth");
				} else if (PatternSpec.match_simple (">PASSWORD*'Private Key'*password*", line)) {
					this.authentication_required (AuthenticationModes.PASSWORD_ONLY, "Private Key");
				} else if (this._auth_step != AuthenticationSteps.NONE &&
				    (PatternSpec.match_simple ("SUCCESS: '%s'*username*".printf (this._auth_type), line) ||
					PatternSpec.match_simple ("SUCCESS: '%s'*password*".printf (this._auth_type), line)) ) {
					authenticate_async ();				
				} else if (PatternSpec.match_simple ("*PASSWORD*Verification*Failed*'Auth'*", line)) {
					if (!_suppress_auth_failed)
						this.authentication_failed (AuthenticationModes.USERNAME_PASSWORD, "Auth");
				} else if (PatternSpec.match_simple ("*PASSWORD*Verification*Failed*'Private Key'*", line)) {
					if (!_suppress_auth_failed)
						this.authentication_failed (AuthenticationModes.PASSWORD_ONLY, "Private Key");
				} else if (PatternSpec.match_simple ("*FATAL*ERROR*", line)) {
					this.control_channel_fatal_error (line);
				} else if (PatternSpec.match_simple (">STATE:*,ASSIGN_IP,*", line)) {
					this._info.assigned_ip = extract_ip_address (line);
				}
				this.control_channel_data_received (line);
			}
		}

		private string extract_ip_address (string line)
		{
			string[] toks = line.split (",",5);
			if (toks[3] != null) {
				return toks[3];
			} else {
				return _("unknown");
			}
		}

		public void send (string data)
		{
                        _client.send (data);
			if (PatternSpec.match_simple ("password \"*\"*", data))
				this.control_channel_data_sent ("password ******** sent");
			else
				this.control_channel_data_sent (data);
		}

		public new void connect ()
		{
                        this.status = ConnectionStates.CONNECTING;
                        _client.send ("hold release\n");
		}

		public void disconnect ()
		{
                        this.status = ConnectionStates.DISCONNECTING;
                        _client.send ("signal SIGHUP\n");
		}

		public void authenticate (string type, string? username, string? password)
		{
			return_if_fail (username != null || password != null);

			this._auth_type = type;
			this._auth_username = username;
			this._auth_password = password;
			if (username == null)
				this._auth_step = AuthenticationSteps.USERNAME;
			else
				this._auth_step = AuthenticationSteps.NONE;
			authenticate_async ();
		}

		private void authenticate_async ()
		{
			string data;

			switch (this._auth_step) {
				case  AuthenticationSteps.NONE:
					if (this._auth_username != null) {
						this._auth_step = AuthenticationSteps.USERNAME;
						data = "username \"%s\" \"%s\"\n".printf (this._auth_type, this._auth_username);
						send (data);
					}
					break;
				case  AuthenticationSteps.USERNAME:
					if (this._auth_password != null) {
						this._auth_step = AuthenticationSteps.PASSWORD;
						data = "password \"%s\" \"%s\"\n".printf (this._auth_type, this._auth_password);
						send (data);
					}
					break;
				default:
					this._auth_step = AuthenticationSteps.NONE;
					break;
			}
		}

		public void cancel_authentication (string type, string username)
		{
			this._suppress_auth_failed = true;
			/* fake authentication, need to search method */
			if (username != null)
				username = "*";

			this.authenticate (type, username, "*");
		}
	}
}
