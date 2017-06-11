package br.com.bsoares.air.airtwitterhardware
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	
	/**
	 * Message Control
	 * Control messages between the Arduino and in AIR
	 * Application using Serial Proxy.
	 * 
	 * @author Bruno Soares
	 * @link   http://www.bsoares.com.br
	 */
	public class MessageControl extends EventDispatcher
	{
		// Properties
		private var _host:String;
		private var _port:uint;
		private var _socket:Socket;
		private var _messages:Array; 
		private var _currentMessage:uint;
		private static var _instance:MessageControl;
		private static var _allowInstantiation:Boolean = false;
		
		// Constructor
		public function MessageControl()
		{
			if (!_allowInstantiation)
				throw new Error("Use instance property (this is a Singleton Class).");
			init();
		}
		
		// Logic
		private function init():void
		{
			_host = "127.0.0.1";
			// COM2
			_port = 5332;
			_messages = [ ];
			_currentMessage = 0;
			socketConnect();
		}
		
		private function socketConnect():void
		{
			_socket = new Socket();
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			_socket.addEventListener(Event.CLOSE, onSocketClose);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketIoError);
			_socket.connect(_host, _port);
		}
		
		private function processData(data:String):void
		{
			trace("Arduino command:", data);
			switch (true)
			{
				// Send next message
				case data == "2" || data == "0":
				{
					sendNextMessage();
					break;
				}
				// Send previous message
				case data == "1":
				{
					sendPreviousMessage();
					break;
				}
			}
		}
		
		private function sendMessage(message:String):void
		{
			if (message == null || message == "")
				return;
			
			trace("Message:", message);
			
			// MESSAGE_START
			_socket.writeUTFBytes("^");
			_socket.flush();
			
			// MESSAGE
			for (var i:uint = 0; i < message.length; i++)
			{
				_socket.writeUTFBytes(message.charAt(i));
			}
			_socket.flush();
			
			// MESSAGE_END
			_socket.writeUTFBytes("~");
			_socket.flush();
			
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function sendNextMessage():void
		{
			_currentMessage = _currentMessage == _messages.length - 1 ? 0 : _currentMessage + 1;
			sendMessage(_messages[_currentMessage]);
		}
		
		private function sendPreviousMessage():void
		{
			_currentMessage = _currentMessage == 0 ? _messages.length - 1 : _currentMessage - 1;
			sendMessage(_messages[_currentMessage]);
		}
		
		// Events
		private function onSocketData(event:ProgressEvent):void
		{
			while (_socket.bytesAvailable > 0)
				processData(_socket.readUTFBytes(1));
		}
		
		private function onSocketClose(event:Event):void
		{
			socketConnect();
		}
		
		private function onSocketIoError(event:IOErrorEvent):void
		{
			trace(event.text);
		}
		
		// Getters and Setters
		public static function get instance():MessageControl
		{
			if (_instance == null) {
				_allowInstantiation = true;
				_instance = new MessageControl();
				_allowInstantiation = false;
			}
			return _instance;
		}
		
		public function set messages(value:Array):void
		{
			_currentMessage = 0;
			_messages = value;
			if (_messages.length > 0)
				sendMessage(_messages[0]);
		}
		
		public function get messages():Array
		{
			return _messages;
		}
		
		public function get currentMessage():uint
		{
			return _currentMessage;
		}
	}
}