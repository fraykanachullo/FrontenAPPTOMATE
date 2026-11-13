# TFLite: el delegado GPU es opcional y no se empaqueta; sin esto R8 falla en release
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-keep class org.tensorflow.lite.** { *; }
