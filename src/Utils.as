package 
{
	/**
	 * ...
	 * @author dxy
	 */
	public class Utils 
	{
		
		public function Utils() 
		{

		}
		
		public static function number2Time(s:Number):String
		{
			s = Math.floor(s);
			var m:Number = 0;
			var h:Number = 0;
			if (isNaN(s)) {
				s = 0;
			}
			if (s / 3600 >= 1) {
				h = Math.floor(s / 3600);
				s -= h * 3600;
			}
			if (s / 60 >= 1) { 
				m = Math.floor(s / 60);
				s -= m * 60;
			}
			return (h < 10 ? '0' + h : h) + ':' + (m < 10 ? '0' + m : m) + ':' + (s < 10 ? '0' + s : s);
		}
		
		public static function date2String(date:Date):String
		{
			var year:String = (date.fullYear + "-");
			var month:String = ((date.month + 1) + "-");
			var day:String;
			var hours:String;
			var minutes:String;
			var seconds:String;
			var milliseconds:String;

			if (date.date < 10)
			{
				day = (("0" + date.date) + " ");
			} else {
				day = (date.date + " ");
			}
			if (date.hours < 10)
			{
				hours = (("0" + date.hours) + ":");
			}
			else
			{
				hours = (date.hours + ":");
			}
			if (date.minutes < 10)
			{
				minutes = (("0" + date.minutes) + ":");
			}
			else
			{
				minutes = (date.minutes + ":");
			}
			if (date.seconds < 10)
			{
				seconds = (("0" + date.seconds) + ".");
			}
			else
			{
				seconds = (date.seconds + ".");
			}
			if (date.milliseconds < 10) {
				milliseconds = ("00" + date.milliseconds);
			} else if (date.milliseconds < 100) {
				milliseconds = ("0" + date.milliseconds);
			} else {
				milliseconds = (date.milliseconds + "");
			}
			return (((((((year + month) + day) + hours) + minutes) + seconds) + milliseconds));
		}
		
		public static function date2Str(date:Date):String
		{
			var year:String = date.fullYear.toString();
			var month:String = (date.month + 1) + '';
			var day:String;
			var hours:String;
			var minutes:String;
			var seconds:String;
			var milliseconds:String;

			if (date.date < 10)
			{
				day = (("0" + date.date));
			} else {
				day = date.date.toString();
			}
			if (date.hours < 10)
			{
				hours = (("0" + date.hours));
			}
			else
			{
				hours = date.hours.toString();
			}
			if (date.minutes < 10)
			{
				minutes = (("0" + date.minutes));
			}
			else
			{
				minutes = date.minutes.toString();
			}
			if (date.seconds < 10)
			{
				seconds = (("0" + date.seconds));
			}
			else
			{
				seconds = date.seconds.toString();
			}
			//if (date.milliseconds < 10) {
				//milliseconds = ("00" + date.milliseconds);
			//} else if (date.milliseconds < 100) {
				//milliseconds = ("0" + date.milliseconds);
			//} else {
				//milliseconds = (date.milliseconds + "");
			//}
			return (((((((year + month) + day) + '_' + hours) + minutes) + seconds)));
		}	
		
		public static function formatMsg(msg:String):String
		{
			var re:String = '[' + date2String(new Date) + '] ' + msg;
			trace(re);
			return re;
		}
	}

}