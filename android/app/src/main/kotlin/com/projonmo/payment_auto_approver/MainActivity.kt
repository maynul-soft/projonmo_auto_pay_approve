package com.projonmo.payment_auto_approver

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.projonmo.payment_auto_approver/sms"
    private var methodChannel: MethodChannel? = null
    private var smsObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getQueuedSms" -> {
                    val prefs = getSharedPreferences("sms_queue_prefs", Context.MODE_PRIVATE)
                    val rawSet = prefs.getStringSet("pending_sms", emptySet()) ?: emptySet()
                    val list = rawSet.map { entry ->
                        val parts = entry.split("|||", limit = 3)
                        if (parts.size == 3) {
                            mapOf(
                                "timestamp" to (parts[0].toLongOrNull() ?: System.currentTimeMillis()),
                                "sender" to parts[1],
                                "body" to parts[2]
                            )
                        } else {
                            emptyMap()
                        }
                    }.filter { it.isNotEmpty() }
                    result.success(list)
                }
                "clearQueuedSms" -> {
                    val prefs = getSharedPreferences("sms_queue_prefs", Context.MODE_PRIVATE)
                    prefs.edit().remove("pending_sms").apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Connect SmsReceiver live listener
        SmsReceiver.listener = { sender, body, timestamp ->
            runOnUiThread {
                methodChannel?.invokeMethod(
                    "onSmsReceived",
                    mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to timestamp
                    )
                )
            }
        }

        // Register ContentObserver on SMS Inbox as watchdog
        try {
            smsObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    runOnUiThread {
                        methodChannel?.invokeMethod("onInboxChanged", null)
                    }
                }
            }
            contentResolver.registerContentObserver(
                Telephony.Sms.Inbox.CONTENT_URI,
                true,
                smsObserver!!
            )
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        SmsReceiver.listener = null
        smsObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        super.onDestroy()
    }
}
