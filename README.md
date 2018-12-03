<!-- TOC -->

- [本文目标](#本文目标)
- [如何从PCM数据中取出音频频谱](#如何从pcm数据中取出音频频谱)
  - [WAV文件与波形图](#wav文件与波形图)
  - [什么是PCM(Pulse-code modulation)](#什么是pcmpulse-code-modulation)
  - [什么是频谱(frequency spectrum)](#什么是频谱frequency-spectrum)
  - [什么是傅立叶变换(Fourier Transform)](#什么是傅立叶变换fourier-transform)
    - [想了解一下傅立叶的高端思想是啥？](#想了解一下傅立叶的高端思想是啥)
  - [那么这东西具体怎么操作呢？](#那么这东西具体怎么操作呢)
- [RealtimeWaveform_CoreAudio](#realtimewaveform_coreaudio)


<!-- /TOC -->
# 本文目标
本文的目标是在无数字信号处理基础的情况背景下说明PCM转频谱的原理。


# 如何从PCM数据中取出音频频谱
通常音频播放软件的频谱图就是频谱数据了，一般音频数据有两种可视化的模式，波形图和频谱图。


## WAV文件与波形图
![wave form](https://res.cloudinary.com/demo/video/upload/h_200,w_500,fl_waveform/bumblebee.png)
[WAV](https://zh.wikipedia.org/wiki/WAV)文件格式可以记录多种数据类型，其中头部分记录的是音频数据类型，声道数量，采样率，采样深度之类的信息。
其中数据类型为*1*时表示此WAV文件使用的是PCM编码的数据，**也就是从理论上来说WAV里面的数据不一定就是PCM**。

PCM格式的数据，表示的就是波形图。

类似的, 苹果的[AIFF](https://zh.wikipedia.org/wiki/%E9%9F%B3%E9%A2%91%E4%BA%A4%E6%8D%A2%E6%96%87%E4%BB%B6%E6%A0%BC%E5%BC%8F)也可以作为PCM的容器。


## 什么是PCM(Pulse-code modulation)
[wiki](https://zh.wikipedia.org/wiki/%E8%84%88%E8%A1%9D%E7%B7%A8%E7%A2%BC%E8%AA%BF%E8%AE%8A)上有详细解释。
*我对这个编码的理解*就是声波冲击到麦克风上面的时候产生的压力的数值，或者声音震动使麦克风的那个膜产生了震动的幅度值。
声音大的话震动的幅度会大一些。

由于声音是一个连续的数据, 而计算机处理的是离散的数据，所以需要对声音进行编码采集，才有了采样率这个事儿。
而且PCM只是表示那个幅值，本身并不包含采样率，频道之类的信息，所以才需要WAV的头信息进行说明，不然拿到数据了都不知道这到底是个啥。


## 什么是频谱(frequency spectrum)
![Frequency specturm chart](https://i.stack.imgur.com/WHGyR.png)
声音是通过震动产生的，而震动是有不同频率的。比较低沉的声音震动频率就偏低，而尖锐的声音振动频率就偏高。

不同于波形图随着时间的变长绘制的内容也越来越长，频谱图长度始终是一定的，但是会上下波动。


## 什么是傅立叶变换(Fourier Transform)
为啥出来这么个东西呢？
![波形图和频谱](https://upload.wikimedia.org/wikipedia/commons/f/f1/Voice_waveform_and_spectrum.png)
*上图中左边是波形图，右边是其对应的频谱*

傅立叶变换是啥就不讲了，反正在这里咱们就是用它来把PCM转换成频谱图的。


### 想了解一下傅立叶的高端思想是啥？
* [傅里叶分析之掐死教程](https://zhuanlan.zhihu.com/p/19763358)
* [傅里叶变换和正弦函数和欧拉公式](https://blog.csdn.net/u010138758/article/details/73800339)
* [从零开始的频域水印完全解析](https://zhuanlan.zhihu.com/p/27632585)


## 那么这东西具体怎么操作呢？
简单的从流程上说，就是
1. 拿到PCM数据
2. 把这个数据傅立叶变换一下
3. 傅立叶变换之后的输出显示出来

大功告成，所有内容都可以在工程里面看到

*示例项目的傅立叶变换在苹果体系内使用了Accelerate框架*


# RealtimeWaveform_CoreAudio
Draw waveform from CMSampleBuffer

示例如何从CMSampleBuffer中读出音频源数据并展示出来。

关键方法：[文档](https://developer.apple.com/documentation/coremedia/1489191-cmsamplebuffergetaudiobufferlist) `CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer` 

其中第三个参数`bufferListSize`需要注意，如果不对的话会返回`kCMSampleBufferError_ArrayTooSmall`，无法成功获取`AudioBufferList`. 根据[这里](https://lists.apple.com/archives/quicktime-api/2013/Apr/msg00015.html)看到的信息，可能需要获取两次。

另外取出的`AudioBuffer`里面的`mData`的数据类型不固定，可能是浮点值，也可能是有符号的16位整型，并且字节序也可能不确定，所以处理时需要注意。

