package com.projonmo.payment_auto_approver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        var listener: ((sender: String, body: String, timestamp: Long) -> Unit)? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0].displayOriginatingAddress ?: messages[0].originatingAddress ?: ""
            val timestamp = messages[0].timestampMillis

            val bodyBuilder = StringBuilder()
            for (msg in messages) {
                bodyBuilder.append(msg.displayMessageBody ?: msg.messageBody ?: "")
            }
            val body = bodyBuilder.toString()

            Log.d(TAG, "SMS Received from: $sender (length: ${body.length})")

            // Deliver to live listener if registered
            listener?.invoke(sender, body, timestamp)

            // Also persist to SharedPreferences as backup queue
            context?.let { ctx ->
                val prefs = ctx.getSharedPreferences("sms_queue_prefs", Context.MODE_PRIVATE)
                val existing = prefs.getStringSet("pending_sms", mutableSetOf()) ?: mutableSetOf()
                val updated = HashSet(existing)
                val entry = "$timestamp|||$sender|||$body"
                updated.add(entry)
                prefs.edit().putStringSet("pending_sms", updated).apply()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing incoming SMS", e)
        }
    }
}
