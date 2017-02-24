# XyTestPlayer

版本：v1.3.0

本播放器用于测试直播或点播的各项指标，包括：
- 首屏
- FPS 10s/30s
- 卡顿次数、卡顿时长
- 视频的各项数据：BufferTime、BufferLength、BytesLoaded、MetaData、NetStatus

## 通过ExternalInterface提供的接口

### Method
- setUrl(url:String):void  
    视频地址
- setBufferTime(bufferTime:Number):void  
	设定bufferTime
- setPlayDuration(duration:Number):void  
	设定播放多长时间后自动停止
- printLog():String  
	返回日志
- play():void  
	播放
- stop():void  
	停止
- isPlaying():Boolean  
	是否已开始播放
- getSDKList():String  
	获取可选SDK列表的JSON格式字符串，格式如下：  
	```[{"data": "d1", "label": "l1", "type": "t1", "url": "u1"}, {"data": "d2", "label": "l2", "type": "t2", "url": "u2"}]```  
	label: SDK名称，data: SDK的URL，且第一项总是不使用sdk:{"data":"none","label":"no"}
- setSDK(index:Number = 0):Boolean  
	设定SDK，参数为SDK列表中的索引，默认为0，设定成功则返回true。只能在未播放时设定。
- usedSDK():Number  
	当前使用的SDK，返回SDK列表中的索引
- cacheSDK(value:Boolean = true):Boolean [已废弃] 
	设定是否缓存SDK库，推荐使用缓存，既第一次加载成功后，再次播放不需要重新加载。只能在未播放时设定。
- getMetaData():String  
	返回metadata的JSON格式字符串，在没有触发metadata事件前或停止后是空Object
- getStatus():String  
	返回播放器、NetConnection、NetStream的当前状态，JSON格式字符串
- getInfo():String
	printLog的JSON格式字符串版本

### Event
- onPlayerLoaded  
	播放器初始化完毕时调用
- onMetaData  
	播放器获取metadata时调用
- onError  
	引发异常时调用

### Demo
参看bin/index.html
