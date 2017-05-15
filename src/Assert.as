package
{
	/**
	 * ...
	 * @author ...
	 */
	public class Assert 
	{
		
		static public function assert(cond:Boolean,msg:String = ''):void
		{
			if (!cond)
				throw new Error(msg);
			
		}
		
		static public function require(cond:Boolean,msg:String = ''):void
		{
			if (!cond)
				throw new Error(msg);
			
		}
		
		static public function ensure(cond:Boolean,msg:String = ''):void
		{
			if (!cond)
				throw new Error(msg);
			
		}
		
		static public function invariant(cond:Boolean,msg:String = ''):void
		{
			if (!cond)
				throw new Error(msg);
			
		}
		
	}
}