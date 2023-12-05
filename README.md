# VMscatter Code

## Project Overview

This repository contains the MATLAB simulation code for the VMscatter system, as presented in our paper at NSDI 2020. VMscatter is a versatile MIMO backscatter system leveraging MIMO diversity to significantly reduce bit error rate (BER) and enhance throughput with minimal overhead. Unlike traditional WiFi MIMO backscatter approaches, VMscatter utilizes advanced MIMO features, enabling full diversity gains even under the constraint of non-orthogonal reflected signals from backscatter tags.

## Code Structure

The code is divided into two main parts:

### Proof-of-Concept Simulation
- This is a simplified 2x2 WiFi MIMO Backscatter simulation based on 802.11g. 
- It is designed to provide an understanding of the decoding algorithms used in VMscatter.

### 802.11nHT
- Based on MATLAB's 802.11n Packet Error Rate Simulation for a 2x2 TGn Channel.
- This simulation integrates backscatter modulation and demodulation into the code.
- It accounts for multipath effects, delays, noise, etc.
- The code can be connected to MATLAB's USRP API for real-world experimentation.

## Special Considerations

- In both simulations, careful design of the reference signal is crucial. The matrix for channel estimationg formed by the reference signal and a '0' sequence must be full rank. For example, with a 2x2 '0' sequence backscatter data of [1,1], the reference signal backscatter must be [1,-1] or [-1,1], but not [-1,-1].
- The first method does not require an in-depth estimation of the channel and infers backscatter data based on the channel's phase.
- The second method requires a detailed estimation of the channel. While the real MIMO backscatter channel has infinitely many solutions, any solution can be used for decoding as the information is carried on the phase.
- VMscatter operates on symbol-level modulation, and pilot tracking should be disabled.

## Conclusion

The VMscatter design introduces negligible overheads in terms of hardware cost, energy consumption, and computation, making it a practical solution for advanced MIMO backscatter systems.


# VMscatter代码中文说明

## 项目概述

本代码仓库包含了在NSDI 2020发表的VMscatter系统的MATLAB仿真代码。VMscatter是一种多功能的MIMO反向散射系统，通过利用MIMO的多样性特征显著降低比特错误率（BER）并提高吞吐量，同时几乎不增加额外开销。与传统的WiFi MIMO反向散射方法不同，VMscatter利用了MIMO技术的先进特性，在反向散射标签不能控制反射信号正交的限制下，实现了与传统MIMO系统相同的全多样性增益。

## 代码结构

代码主要分为两部分：

### 概念验证仿真
- 这是基于802.11g的简化2x2 WiFi MIMO反向散射仿真。
- 旨在帮助用户理解VMscatter中使用的解码算法。

### 802.11nHT仿真
- 基于MatLab的802.11n 2x2 TGn信道的包错误率仿真。
- 将反向散射的调制和解调集成到代码中。
- 考虑了多径效应、延迟、噪声等因素。
- 此代码可以连接到MatLab的USRP API，以实现真实环境下的实验。

## 特别注意事项

- 在两种仿真中，都需要精心设计参考信号。由参考信号和'0'序列组成的测试信道矩阵必须是满秩的。例如，对于2x2的'0'序列反向散射数据[1,1]，参考信号中的反向散射必须是[1,-1]或[-1,1]，而不能是[-1,-1]。
- 第一种方法不需要深入估计信道，而是根据信道的相位来推断反向散射数据。
- 第二种方法需要深入估计信道。尽管真实的MIMO反向散射信道有无穷多解，但任何解都可用于解码，因为信息是载在相位上的。
- VMscatter采用符号级调制，需要关闭导频跟踪。

## 结论

VMscatter设计引入的额外开销（包括硬件成本、能耗和计算）微乎其微，使其成为实用的先进MIMO反向散射系统解决方案。
