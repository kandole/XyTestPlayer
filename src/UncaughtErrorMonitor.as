package 
{
	import flash.display.LoaderInfo;
	import flash.events.UncaughtErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	/**
	 * ...
	 * @author dxy
	 */
	public class UncaughtErrorMonitor 
	{
		
		private var _id:Number = -1;
		private var _name:String = '';
		private var _message:String = '';
		private var _stack:String = '';
		private var _callback:Function;
		
		public function UncaughtErrorMonitor(loaderInfo:LoaderInfo, callback:Function) 
		{
			_callback = callback;
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		}
		
		public static function init(loaderInfo:LoaderInfo, callback:Function):UncaughtErrorMonitor
		{
			return new UncaughtErrorMonitor(loaderInfo, callback)
		}
		
		public function uncaughtErrorHandler(event:UncaughtErrorEvent):void
		{
			//event.preventDefault();
			if (event["error"] is Error)
            {
                var error:Error = event.error as Error;
				_id = error.errorID;
				_name = error.name;
				_stack = error.getStackTrace();
				_message = error.message;
            }
            else if (event["error"] is ErrorEvent)
            {
                var errorEvent:ErrorEvent = event.error as ErrorEvent;
				_id = errorEvent["errorID"];
				_name = errorEvent.type;
				_message = errorEvent.text;
            }
            else
            {
				return;
            }
			
			var obj:Object = {
				'errorID': _id,
				'name': _name,
				'message': _message,
				'stackTrace': _stack
			};
			_callback(obj);
		}
		
	}

}