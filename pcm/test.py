import matplotlib.pyplot as plt
import numpy as np
import math


from data import *


def foo(pcm_data, samplerate, current_time):
    x_axis = np.arange(0, len(pcm_data) - 1) / len(pcm_data) * samplerate
    complex_data = [x+0j for x in pcm_data]
    result = np.fft.fft(complex_data)
#    result = np.fft.fft(pcm_data)
    length = len(pcm_data) // 2
    amplitudes = [math.sqrt(x.imag * x.imag + x.real * x.real) for x in result[:length]]
    plt.plot(x_axis[:length], amplitudes)
    plt.title('{}s sample count: {}'.format(current_time, len(pcm_data)))
    plt.xlabel('{}Hz'.format(samplerate))
    plt.show()


def bar():
    dp = PCM_data_provider()
    totol_duration = len(dp.data) / dp.samplerate
    step = 1.0
    current_time = 0
    while current_time < totol_duration:
        d = dp.get_data_at(current_time, step)
        current_time += step
        print('current time: {}'.format(current_time))
        foo(d, current_time)


def baz():
    dp = PCM_data_provider()
    window = 512
    total_number_of_data = len(dp.data)
    current_index =  144000
    while current_index < total_number_of_data:
        d = dp.data[current_index:current_index+window]
        current_time = current_index / dp.samplerate
        print('current time: {}'.format(current_index / dp.samplerate))
        foo(d, dp.samplerate, current_time)
        current_index += window


if __name__ == '__main__':
    baz()
