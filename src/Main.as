package
{
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import mx.core.TextFieldAsset;
	
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.utils.Timer;
	import fl.controls.Button;
	import fl.controls.TextInput;
	import fl.controls.UIScrollBar;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.external.ExternalInterface;

	import Utils;

	/**
	 * ...
	 * @author dxy
	 */
	public class Main extends Sprite 
	{
		private var _vFLV:Video;
		private var _nc:NetConnection;
		private var _ns:NetStream;
		private var _url:String = "";
		
		private var _urlText:TextInput;
		private var _openBtn:Button;
		private var _stopBtn:Button;
		private var _bufferTimeLbl:TextField;
		private var _bufferTimeIpt:TextInput;
		private var _currentTimeTxt:TextField;
		private var _versionTxt:TextField;
		private var _logLbl:TextField;
		private var _logSb:UIScrollBar;
		private var _playDurationLbl:TextField;
		private var _playDurationIpt:TextInput;
		private var _downLogBtn:Button;
		
		private var _fpStartTick:Number;
		//private var _fpEndTick:Number;
		private var _videoStartTick:Number;
		//private var _fps:Number;
		private var _isFirstBufferFull:Boolean;
		
		private var _playTimer:Timer;
		private var _logTimer:Timer;
		private var _autoStopTimer:Timer;
		
		private var _infoQueue:Object;
		
		private var _bufferEmptyQueue:Array;
		private var _bufferFullQueue:Array;
		private var _interruptQueue:Object;
		private var _fpsQueue:Array;
		
		private var _logMsg:String;
		private var _fileRefer:FileReference;
		private var _currentStatus:Object = {
				level: "status",
				code: "Player.Init"
		};
		private var _metadata:Object = {};
		
		private var _nameMapping:Object = {
			"firstScreen": 'FirstScreen(ms)',
			"metaData": 'MetaData',
			"bufferTime": 'BufferTime(s)',
			"bufferLength": 'BufferLength(s)',
			"bytesLoaded": "BytesLoaded(b)",
			"bytesTotal": "BytesTotal(b)",
			"fps": "FPS",
			"avgFps": "avgFPS/10s", // 10s内平均FPS
			"avgFps_30": "avgFPS/30s", // 30s内平均FPS
			"totalInterruptCount": 'totalInterruptCount', // 总卡顿次数
			"totalInterruptTime": 'totalInterruptTime(ms)', // 总卡顿时长(ms)
			"avgInterruptCount": 'avgInterruptCount/10s', // 10s内卡顿次数
			"avgInterruptTime": 'avgInterruptTime/10s(ms)', // 10s内卡顿时长(ms)
			"avgInterruptCount_30": 'avgInterruptCount/30s', // 30s内卡顿次数
			"avgInterruptTime_30": 'avgInterruptTime/30s(ms)', // 30s内卡顿时长(ms)
			"netStatus": "NetStatus"
		};
		

		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point

			stage.scaleMode = StageScaleMode.NO_SCALE;
//			stage.align = StageAlign.LEFT;
			stage.align = StageAlign.TOP_LEFT;

			initParams();

			_vFLV = new Video();
			_vFLV.x = 20;
			_vFLV.y = 80;
			_vFLV.width = 600;
			_vFLV.height = 337.5;

			initControls();

			_playTimer = new Timer(100);
			_playTimer.addEventListener(TimerEvent.TIMER, updateProgress);
			
			_logTimer = new Timer(1000);
			_logTimer.addEventListener(TimerEvent.TIMER, infoHandler);

			if (ExternalInterface.available) {
				ExternalInterface.addCallback("setUrl", setUrl);
				ExternalInterface.addCallback("setBufferTime", setBufferTime);
				ExternalInterface.addCallback("setPlayDuration", setPlayDuration);
				ExternalInterface.addCallback("printLog", printLog);
				ExternalInterface.addCallback("play", playEx);
				ExternalInterface.addCallback("stop", stopEx);
				ExternalInterface.addCallback("isPlaying", isPlaying);
				ExternalInterface.addCallback("getMetaData", getMetaData);
				ExternalInterface.addCallback("getStatus", getStatus);
				
				ExternalInterface.call("onPlayerLoaded");
			}
			
		}
		
		// -↓- public interface -↓-
		public function setUrl(url:String):void
		{
			if (_urlText) {
				_urlText.text = url;
			}
		}
		
		public function setBufferTime(bufferTime:Number):void
		{
			if (_bufferTimeIpt) {
				_bufferTimeIpt.text = bufferTime.toString();
			}
		}
		
		public function setPlayDuration(duration:Number):void
		{
			if (_playDurationIpt) {
				_playDurationIpt.text = duration.toString();
			}
		}
		
		public function printLog():String
		{
			return _logMsg;
		}
		
		public function playEx():void
		{
			openVideo(null);
		}
		
		public function stopEx():void
		{
			stopVideo(null);
		}
		
		public function isPlaying():Boolean
		{
			return _stopBtn.enabled;
		}
		
		public function getStatus():String
		{
			return JSON.stringify(_currentStatus);
		}
		
		public function getMetaData():String
		{
			return JSON.stringify(_metadata);
		}
		// -↑- public interface -↑-
		
		private function initParams():void
		{
			_currentStatus = {
				level: "status",
				code: "Player.Init"
			};
			_metadata = {};
			_infoQueue = {
				"firstScreen": 0,
				"metaData": "No MetaData!",
				"bufferTime": 0,
				"bufferLength": 0,
				"bytesLoaded": 0,
				"bytesTotal": 0,
				"fps": 0,
				"avgFps": 0,
				"avgFps_30": 0,
				"totalInterruptCount": 0,
				"totalInterruptTime": 0,
				"avgInterruptCount": 0,
				"avgInterruptTime": 0,
				"avgInterruptCount_30": 0,
				"avgInterruptTime_30": 0,
				"netStatus": ""
			};
			_bufferEmptyQueue = new Array;
			_bufferFullQueue = new Array;
			_interruptQueue = new Object;
			//_fps = 0;
			_fpsQueue = new Array;
			_isFirstBufferFull = false;
		}
		
		private function initControls():void
		{
			_urlText = new TextInput();
			//_urlText.text = "http://pullsdk.test.live.00cdn.com/live/stream1.flv";
			_urlText.text = "http://demo.vod.u.00cdn.com/FLV/big_buck_bunny_750kbps_480p.flv";
			_urlText.x = 20;
			_urlText.y = 20;
			_urlText.width = 400;

			_openBtn = new Button();
			_openBtn.label = "播放";
			_openBtn.width = 40;
			_openBtn.x = _urlText.x + _urlText.width + 10;
			_openBtn.y = 20;
			_openBtn.addEventListener(MouseEvent.CLICK, openVideo);

			_stopBtn = new Button();
			_stopBtn.label = "停止";
			_stopBtn.x = _openBtn.x + _openBtn.width + 10;
			_stopBtn.y = _openBtn.y;
			_stopBtn.width = 40;
			_stopBtn.enabled = false;
			_stopBtn.addEventListener(MouseEvent.CLICK, stopVideo);
			//_stopBtn.enabled = false;
			
			_bufferTimeLbl = new TextField();
			_bufferTimeLbl.text = 'BufferTime:';
			_bufferTimeLbl.x = _stopBtn.x + _stopBtn.width + 10;
			_bufferTimeLbl.y = _stopBtn.y;
			_bufferTimeLbl.width = 65;
			
			_bufferTimeIpt = new TextInput();
			_bufferTimeIpt.text = "1";
			_bufferTimeIpt.x = _bufferTimeLbl.x + _bufferTimeLbl.width + 5;
			_bufferTimeIpt.y = _bufferTimeLbl.y;
			_bufferTimeIpt.width = 30;

			_versionTxt = new TextField;
			_versionTxt.text = 'v1.3.0';
			_versionTxt.x = _bufferTimeIpt.x + _bufferTimeIpt.width + 5;
			_versionTxt.y = _bufferTimeIpt.y;
			_versionTxt.width = 80;
			
			_playDurationLbl = new TextField();
			_playDurationLbl.text = '播放时长(s):';
			_playDurationLbl.x = _urlText.x;
			_playDurationLbl.y = _urlText.y + _urlText.height + 10;
			_playDurationLbl.width = 80;
			
			_playDurationIpt = new TextInput();
			_playDurationIpt.text = '0'; // 没有限制
			_playDurationIpt.x = _playDurationLbl.x + _playDurationLbl.width + 5;
			_playDurationIpt.y = _playDurationLbl.y;
			_playDurationIpt.width = 50;
			
			_downLogBtn = new Button();
			_downLogBtn.label = "LOG下载";
			_downLogBtn.x = _playDurationIpt.x + _playDurationIpt.width + 10;
			_downLogBtn.y = _playDurationIpt.y;
			_downLogBtn.width = 80;
			_downLogBtn.addEventListener(MouseEvent.CLICK, downloadLog);
			
			addChild(_urlText);
			addChild(_openBtn);
			addChild(_stopBtn);
			addChild(_bufferTimeLbl);
			addChild(_bufferTimeIpt);
			addChild(_versionTxt);
			addChild(_playDurationLbl);
			addChild(_playDurationIpt);
			addChild(_downLogBtn);
			
			_fileRefer = new FileReference();
			_fileRefer.addEventListener(Event.OPEN, downLogOpenHandler);
			_fileRefer.addEventListener(Event.COMPLETE, downLogCompleteHandler);
			_fileRefer.addEventListener(ProgressEvent.PROGRESS, downLogProgressHandler);
			_fileRefer.addEventListener(Event.CANCEL, downLogCancelHandler);
			_fileRefer.addEventListener(IOErrorEvent.IO_ERROR, downLogIOErrorHandler);
		}

		private function netStatusHandler(event:NetStatusEvent):void
		{
			_infoQueue.netStatus += "\n\t" + log(event.info.level + ': ' + event.info.code);

			_currentStatus = {
				level: event.info.level,
				code: event.info.code
			};
			
			switch (event.info.level) {
				case "error":
					if (_logLbl) {
						_logLbl.htmlText += "\n" + event.info.code + "\n";
					}
					break;
			}
			
			switch (event.info.code) {
                case "NetConnection.Connect.Success":
                    connectStream();
                    break;
                case "NetStream.Play.StreamNotFound":
                    trace("Stream not found: " + _url);
                    break;
				case "NetStream.Play.Start":
					//trace("play start");
					_playTimer.start();
					_logTimer.start();
					break;
				case "NetStream.Buffer.Full":
					if (!_isFirstBufferFull) { // 首屏
						_isFirstBufferFull = true;
						_videoStartTick = (new Date).getTime();
						var duration:Number = _videoStartTick - _fpStartTick;
						_infoQueue.firstScreen = duration;
						trace("first buffer full: " + duration + ', time: ' + _videoStartTick);
					} else {
						var curTick:Number = (new Date).getTime();
		
						var fullLen:Number = _bufferFullQueue.length;
						var emptyLen:Number = _bufferEmptyQueue.length;
						
						if (emptyLen > 0) {
							if (fullLen + 1 != emptyLen) {
								trace('full + 1 != empty');
								// buffer没有empty，再次full的情况，不能作为卡顿
								return;
							}
							_bufferFullQueue.push(curTick);
							fullLen = _bufferFullQueue.length;
							var interruptCount:String = _bufferEmptyQueue.map(function (emptyTick:Number, index:Number, queue:Array):String {
								//trace("--a:" + Utils.number2Time(Math.floor((emptyTick - _videoStartTick) / 1000)));
								return Utils.number2Time(Math.floor((emptyTick - _videoStartTick) / 1000));
							}).join(', ');
							_infoQueue.totalInterruptCount = emptyLen + " [" + interruptCount + "]";
							
							_interruptQueue[curTick] = curTick - _bufferEmptyQueue[emptyLen - 1];
							
							if (fullLen > 0) {
								var totalTime:Number = 0;
								var interruptArray:Array = [];
								for (var i:int = 0; i < fullLen; i++ ) {
									totalTime += _interruptQueue[_bufferFullQueue[i]];
									interruptArray.push(_interruptQueue[_bufferFullQueue[i]]);
								}
								_infoQueue.totalInterruptTime = totalTime + ' [' + interruptArray.join(', ') + ']';
								trace("==q: " + _infoQueue.totalInterruptTime);
							}
						}
					}
					
					//trace("Stream buffer full: " + _ns.bufferLength + ', ' + _ns.bufferTime);
				
					break;
				case "NetStream.Buffer.Empty":
					var emptyTick:Number = (new Date).getTime();			

					if (_bufferEmptyQueue.length == _bufferFullQueue.length) {
						_bufferEmptyQueue.push(emptyTick);
					} else {
						//_bufferEmptyQueue.splice(_bufferEmptyQueue.length - 1, 1, emptyTick);
						// buffer没有full之前，再次empty的情况，不加入_bufferEmptyQueue
						trace('no full empty+++++');
						
					}
					trace("Stream buffer empty, empty: " + _bufferEmptyQueue.length + ', full: ' + _bufferFullQueue.length);
					break;
				case "NetStream.Video.DimensionChange":
					trace("_vFLV.width: " + _vFLV.videoWidth + ', _vFLV.height: ' + _vFLV.videoHeight);
					setVideoSize(_vFLV.videoWidth, _vFLV.videoHeight);
					break;
				case "NetStream.Play.Stop":
					break;
            }
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace("securityErrorHandler: " + event.errorID);
		}

		private function connectStream():void {
			var startTick:Number = (new Date).getTime();
            addChild(_vFLV);
            _ns = new NetStream(_nc);
            _ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			var bt:Number = Number(_bufferTimeIpt.text);
			if (bt >= 0.1 && bt <= 120) {
				_ns.bufferTime = bt;
			} else {
				_bufferTimeIpt.text = '1';
				_ns.bufferTime = 1;
			}
        	var clientObject:Object = new Object();
			clientObject.onMetaData = onMetaData;
			_ns.client = clientObject;
            _vFLV.attachNetStream(_ns);
            
			if (_url.toLocaleLowerCase().slice(0, 4) == "rtmp") {
				_ns.play(_url.slice(_url.lastIndexOf("/") + 1));
			} else {
				_ns.play(_url);
			}
			trace('[connectStream] ' + ((new Date).getTime() - startTick) + ', time: ' + (new Date).getTime());
        }
		
		private function renderInfoArea():void
		{
			
			if (!_currentTimeTxt || !_logLbl) {
				_currentTimeTxt = new TextField();
				_currentTimeTxt.text = "";
				_currentTimeTxt.width = 150;
				_currentTimeTxt.height = 20;

				_logLbl = new TextField();
				_logLbl.text = "waiting...";
				_logLbl.background = true;
				_logLbl.border = true;
				_logLbl.wordWrap = true;
				_logLbl.multiline = true;
				
				_logSb = new UIScrollBar();

				_logSb.scrollTarget = _logLbl;
				
				addChild(_currentTimeTxt);
				addChild(_logLbl);
				addChild(_logSb);
			}
			
			_currentTimeTxt.x = _vFLV.x;
			_currentTimeTxt.y = _vFLV.y + _vFLV.height + 5;
			
			if (_vFLV.width < _vFLV.height) { // 竖屏
				_logLbl.x = _vFLV.x + _vFLV.width + 10;
				_logLbl.y = _vFLV.y;
				_logLbl.width = 400;
				_logLbl.height = 640;
			} else { // 横屏
				_logLbl.x = _vFLV.x;
				_logLbl.y = _currentTimeTxt.y + _currentTimeTxt.height + 5;
				_logLbl.width = 700;
				_logLbl.height = 400;
			}
			
			_logSb.move(_logLbl.x + _logLbl.width, _logLbl.y);
			_logSb.setSize(_logSb.width, _logLbl.height);
		}

        private function onMetaData(metadata:Object):void
        {
			_infoQueue.netStatus += "\n\t" + log('onMetaData');
			var startTick:Number = (new Date).getTime();
			_currentStatus = {
				level: "status",
				code: "Player.MetaData"
			};
			var md:Object = {};
			if (metadata) {
				var metaDataQueue:Array = [];
				for (var key:String in metadata) {
					metaDataQueue.push(key + ': ' + metadata[key]);
					md[key] = metadata[key];
					//trace(key + ': ' + metadata[key]);
					//if (key.toLocaleLowerCase() == "framerate") {
						//// 设定视频实际的帧率
						//stage.frameRate = metadata[key];
						//trace('set frameRate: ' + stage.frameRate + ', metadata frameRate: ' + metadata[key]);
					//}
				}
				_infoQueue.metaData = metaDataQueue.join(", ");
				
				if (metaDataQueue.length > 0) {
					if (metadata.width && metadata.height) {
						setVideoSize(metadata.width, metadata.height);
					}
				}
			}
			
			_metadata = md;
			if (ExternalInterface.available) {
				ExternalInterface.call("onMetaData", md);
			}

			trace('[onMetaData] ' + ((new Date).getTime() - startTick) + ', time: ' + (new Date).getTime());
			
        }
		
		private function setVideoSize(oriWidth:Number, oriHeight:Number):void
		{
			var unit:Number;
			if (oriWidth < oriHeight) { // 竖屏 
				unit = oriHeight;
			} else { // 横屏
				unit = oriWidth;
			}
				
			// <800, 800~1200, 1200>
			if (unit < 800) {
				_vFLV.width = oriWidth;
				_vFLV.height = oriHeight;
			} else if (unit >= 800 && unit < 1200) {
				_vFLV.width = oriWidth * 3 / 5;
				_vFLV.height = oriHeight * 3 / 5;
			} else if (unit >= 1200 && unit < 2000) { 
				_vFLV.width = oriWidth / 2;
				_vFLV.height = oriHeight / 2;
			} else {
				_vFLV.width = oriWidth / 4;
				_vFLV.height = oriHeight / 4;
			}
			trace('origin, h: ' + oriHeight + ', w: ' + oriWidth);
			trace('modify, h: ' + _vFLV.height + ', w: ' + _vFLV.width);
			
			renderInfoArea();
		}

        private function onPlayStatus(status:Object):void
        {
        	trace('onPlayStatus: ' + status);
        }

        private function onXMPData(data:Object):void
        {
        	trace('onXMPData: ' + data);
        }
		
		public function onBWDone():void {
		}

        private function openVideo(event:MouseEvent):void
        {
        	_url = _urlText.text;
			_fpStartTick = (new Date).getTime();
        	
			_nc = new NetConnection();
			_nc.client = this;
			_nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			
			if (_url.toLocaleLowerCase().slice(0, 4) == "rtmp") {
				_nc.connect(_url.slice(0, _url.lastIndexOf("/") + 1));
			} else {
				_nc.connect(null);
			}
			
			_openBtn.enabled = false;
			_stopBtn.enabled = true;
		
			if (_playDurationIpt) {
				var duration:Number = isNaN(parseInt(_playDurationIpt.text)) ? 0 : parseInt(_playDurationIpt.text);				
				if (duration > 0) {
					trace('add autoStopTimer');
					_autoStopTimer = new Timer(duration * 1000 + 500, 1);
					_autoStopTimer.addEventListener(TimerEvent.TIMER, autoStopHandler);
					_autoStopTimer.start();
				}	
			}
			
			renderInfoArea();
        
			trace('[openVideo] ' + ((new Date).getTime() - _fpStartTick) + ', time: ' + (new Date).getTime());
		}

		private function stopVideo(event:MouseEvent):void
		{
			_ns.close();
			initParams();
			_nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			//_vFLV.removeEventListener(Event.EXIT_FRAME, fpsCountHandler);
			if (_autoStopTimer) {
				if (_autoStopTimer.running) {
					_autoStopTimer.stop();
				}
				_autoStopTimer.removeEventListener(TimerEvent.TIMER, autoStopHandler);
				_autoStopTimer = null;
			}
			
			_playTimer.stop();
			_logTimer.stop();
			_openBtn.enabled = true;
			_stopBtn.enabled = false;
		}
		
		private function downloadLog(event:MouseEvent):void
		{
			var fileName:String = 'XYTest_' + Utils.date2Str(new Date) + '.log';
			_fileRefer.save(_logMsg, fileName);
		}
		
		private function downLogOpenHandler(event:Event):void
		{
			trace('downLogOpenHandler');
		}
		
		private function downLogProgressHandler(event:ProgressEvent):void
		{
			var progress:Number = Math.round(event.bytesLoaded / event.bytesTotal * 100);
			trace('downLogProgressHandler: ' + progress);
		}
		
		private function downLogCompleteHandler(event:Event):void
		{
			trace('downLogCompleteHandler');
		}
		
		private function downLogCancelHandler(event:Event):void
		{
			trace('downLogCancelHandler');
		}
		
		private function downLogIOErrorHandler(event:IOErrorEvent):void
		{
			trace('downLogIOErrorHandler: ' + event.errorID);
		}

		private function updateProgress(timerEvent:TimerEvent):void
		{
			var fps:Number = _ns.currentFPS;
			_currentTimeTxt.text = Utils.number2Time(_ns.time) + ' | FPS: ' + fps.toFixed(2);
			
			
			// 视频fps
			_fpsQueue.push(fps);
			_infoQueue.fps = fps;
			if (_fpsQueue.length > 300) { // _fpsQueue只保存30s数据
				_fpsQueue.shift();
			}
			
			var fLen:int = _fpsQueue.length;
			var avgFps:Number = 0;
			var avgFps_30:Number = 0;
			var fpsCount:Number = 0;
			var fpsCount_30:Number = 0;
			for (var i:int = fLen - 1; i >= 0 ; i--) {
				if (fLen - i <= 100) { // 在10s內
					avgFps += _fpsQueue[i];
					fpsCount++;
				}
				if (fLen - i <= 300) { // 在30s內
					avgFps_30 += _fpsQueue[i];
					fpsCount_30++;
				} else {
					break;
				}
			}
			_infoQueue.avgFps = (avgFps / fpsCount).toFixed(2);
			_infoQueue.avgFps_30 = (avgFps_30 / fpsCount_30).toFixed(2);
		}
		
		private function infoHandler(timerEvent:TimerEvent):void
		{
			var curTick:Number = (new Date).getTime();
			
			// 10s内平均数据
			var bfLen:int = _bufferFullQueue.length;
			//trace('~~~full length: ' + _bufferFullQueue.length + ', empty length: ' + _bufferEmptyQueue.length);
			var limit:Number = curTick - 10 * 1000;
			var limit_30:Number = curTick - 30 * 1000;
			
			var interruptCount:Number = 0;
			var interruptTime:Number = 0;

			var interruptCount_30:Number = 0;
			var interruptTime_30:Number = 0;
			
			// _bufferFullQueue和_bufferEmptyQueue不清除数据，会不断增大，但循环不会超过30s内的次数
			for (var i:int = bfLen - 1; i >= 0 ; i--) {
				if (_bufferFullQueue[i] > limit) { // 在10s內
					//trace('=-=-=-=-curTick: ' + curTick + ', limit: ' + limit + ', full: ' + _bufferFullQueue[i] + ', empty: ' + _bufferEmptyQueue[i]);
					interruptCount++;
					interruptTime += _interruptQueue[_bufferFullQueue[i]];
				}
				if (_bufferFullQueue[i] > limit_30) { // 在30s內
					//trace('=-=-=-=-curTick: ' + curTick + ', limit: ' + limit_30 + ', full: ' + _bufferFullQueue[i] + ', empty: ' + _bufferEmptyQueue[i]);
					interruptCount_30++;
					interruptTime_30 += _interruptQueue[_bufferFullQueue[i]];
				} else {
					break;
				}
			}
			//trace("~~buffer loop count: " + (bfLen - i));
			_infoQueue.avgInterruptCount = interruptCount;
			_infoQueue.avgInterruptTime = interruptTime;
			
			_infoQueue.avgInterruptCount_30 = interruptCount_30;
			_infoQueue.avgInterruptTime_30 = interruptTime_30;
			
			_infoQueue.bufferTime = _ns.bufferTime;
			_infoQueue.bufferLength = _ns.bufferLength;
			_infoQueue.bytesTotal = _ns.currentFPS;
			_infoQueue.bytesLoaded = _ns.bytesLoaded;
			
			cleanInfo();
			
			addInfo("firstScreen");
			addInfo("metaData", "", "\n\n");

			addInfo("bufferTime");
			addInfo("bufferLength");
			addInfo("bytesLoaded", "", "\n\n");

			addInfo("avgFps");
			addInfo("avgFps_30", "", "\n\n");

			addInfo("avgInterruptCount");
			addInfo("avgInterruptCount_30", "", "\n\n");

			addInfo("avgInterruptTime");
			addInfo("avgInterruptTime_30", "", "\n\n");

			addInfo("totalInterruptCount");
			addInfo("totalInterruptTime", "", "\n\n");

			addInfo("netStatus");
			
			printInfo();

		}
		
		private function autoStopHandler(timerEvent:TimerEvent):void {
			trace('timeout!');
			stopVideo(null);
			//downloadLog(null);
		}
		
		//private function fpsCountHandler(event:Event):void {
			////trace('fps: ' + _fps);
			//_fps++;
		//}
		

		private function cleanInfo():void
		{
			_logMsg = "";
		}
		
		private function addInfo(name:String, preStr:String = "", postStr:String = "\n"):void
		{
			_logMsg += preStr + _nameMapping[name] + ': ' + _infoQueue[name] + postStr;
		}

		private function printInfo():void {
			_logLbl.text = _logMsg;
			_logSb.update();
		}
		
		private function log(msg:String):String {
			var re:String 
			if (_ns) {
				re = Utils.formatMsg("[" + Utils.number2Time(_ns.time) + "] " + msg);
			} else {
				re = Utils.formatMsg(msg);
			}
			return re;
		}
		
	}
	
}