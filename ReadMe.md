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

### Event
- playerLoaded
	播放器初始化完毕调用

### Demo
参看bin/index.html
