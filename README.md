# RealtimeWaveform_CoreAudio
Draw waveform from CMSampleBuffer

示例如何从CMSampleBuffer中读出音频源数据并展示出来。

关键方法：[文档](https://developer.apple.com/documentation/coremedia/1489191-cmsamplebuffergetaudiobufferlist) `CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer` 

其中第三个参数`bufferListSize`需要注意，如果不对的话会返回`kCMSampleBufferError_ArrayTooSmall`，无法成功获取`AudioBufferList`. 根据[这里](https://lists.apple.com/archives/quicktime-api/2013/Apr/msg00015.html)看到的信息，可能需要获取两次。

另外取出的`AudioBuffer`里面的`mData`的数据类型不固定，可能是浮点值，也可能是有符号的16位整型，并且字节序也可能不确定，所以处理时需要注意。

