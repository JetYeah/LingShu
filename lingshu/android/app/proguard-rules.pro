# flutter_local_notifications 用 Gson 把已排期通知缓存落盘（SharedPreferences JSON）。
# R8 full mode 会剥掉 TypeToken 的泛型签名，release 包读缓存时抛
# "Missing type parameter"（cancel 路径首当其冲：删除药品后抽屉不关、
# 柜子不刷新，且该药品的到期提醒可能残留）。
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*

# 通知插件与其依赖的 Gson 反射元数据
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
