package br.com.bsoares.air.airtwitterhardware
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.WindowedApplication;
	import mx.events.FlexEvent;
	
	/**
	 * Air / Flex Twitter Hardware Application
	 * 
	 * @author Bruno Soares
	 * @link   http://www.bsoares.com.br
	 */
	public class AirTwitterHardware extends WindowedApplication
	{
		// Objects of the interface
		public var txtTwitterRss:TextInput;
		public var cmdRead:Button;
		public var lblTwitter:Label;
		public var gridMessages:DataGrid;
		public var cmdReload:Button;
		
		// Properties
		private var _messages:Array;
		private var _twitter:String = "";
		private var _maxMessages:uint = 10;
		private var _lastMessage:String = "";
		private var _timer:Timer;
		private var _timeReload:Number = 10000;
		private var _urlLoader:URLLoader;
		
		// Constructor
		public function AirTwitterHardware()
		{
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
		}
		
		// Logic
		private function init():void
		{
			_timer = new Timer(_timeReload);
			registerLiteners();
			if (txtTwitterRss.text != "")
				loadTwitterRss();
			
		}
		
		private function registerLiteners():void
		{
			cmdRead.addEventListener(MouseEvent.CLICK, onClickRead);
			cmdReload.addEventListener(MouseEvent.CLICK, onClickRead);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			MessageControl.instance.addEventListener(Event.CHANGE, onMessageChange);
		}
		
		private function loadTwitterRss():void
		{
			_urlLoader = new URLLoader();
			_urlLoader.addEventListener(Event.COMPLETE, onCompleteXmlLoad);
			_urlLoader.load(new URLRequest(txtTwitterRss.text));
		}
		
		private function clear():void
		{
			_twitter = "";
			_messages = [ ];
			gridMessages.dataProvider = [ ];
		}
		
		private function parseRssData(data:XML):void
		{
			var lastMessage:String = data..channel.item[0].title.toString();
			if (_lastMessage == lastMessage)
				return;
			_lastMessage = lastMessage;
			
			_twitter = data..channel.description.toString();
			lblTwitter.text = _twitter;
			_messages = [];
			for (var i:uint = 0; i < data..channel.item.length(); i++)
			{
				var message:String = data..channel.item[i].title.toString();
				message = formatTextToLcd(message);
				message = (i + 1) + ") " + message;
				_messages[i] = message;
				if (i == _maxMessages - 1)
					break;
			}
			MessageControl.instance.messages = _messages;
			gridMessages.dataProvider = _messages;
		}
		
		private function formatTextToLcd(text:String):String
		{
			text = removeEspecialChars(text);
			text = text.replace(/[a-z]+:\/\/[^ ]+/, "[LINK]");
			text = text.replace(/^[^:].*: /, "");
			return text;
		}
		
		private function removeEspecialChars(text:String):String
		{
			var arrPatterns:Array = [ ];
			arrPatterns.push({pattern:/[äáàâãª]/g, char:'a'});
			arrPatterns.push({pattern:/[ÄÁÀÂÃ]/g, char:'A'});
			arrPatterns.push({pattern:/[ëéèê]/g, char:'e'});
			arrPatterns.push({pattern:/[ËÉÈÊ]/g, char:'E'});
			arrPatterns.push({pattern:/[íîïì]/g, char:'i'});
			arrPatterns.push({pattern:/[ÍÎÏÌ]/g, char:'I'});
			arrPatterns.push({pattern:/[öóòôõº]/g, char:'o'});
			arrPatterns.push({pattern:/[ÖÓÒÔÕ]/g, char:'O'});
			arrPatterns.push({pattern:/[üúùû]/g, char:'u'});
			arrPatterns.push({pattern:/[ÜÚÙÛ]/g, char:'U'});
			arrPatterns.push({pattern:/[ç]/g, char:'c'});
			arrPatterns.push({pattern:/[Ç]/g, char:'C'});
			arrPatterns.push({pattern:/[ñ]/g, char:'n'});
			arrPatterns.push({pattern:/[Ñ]/g, char:'N'});
			for( var i:uint = 0; i < arrPatterns.length; i++)
			{
				text = text.replace(arrPatterns[i].pattern, arrPatterns[i].char);
			}
			return text;
		}
		
		// Events
		private function onCreationComplete(event:FlexEvent):void
		{
			init();
		}
		
		private function onClickRead(event:MouseEvent):void
		{
			clear();
			if (txtTwitterRss.text == "")
				return;
			loadTwitterRss();
		}
		
		private function onCompleteXmlLoad(event:Event):void
		{
			parseRssData(XML(event.target.data));
		}
		
		private function onMessageChange(event:Event):void
		{
			gridMessages.selectedIndex = MessageControl.instance.currentMessage;
		}
		
		private function onTimer(event:TimerEvent):void
		{
			loadTwitterRss();
		}
	}
}