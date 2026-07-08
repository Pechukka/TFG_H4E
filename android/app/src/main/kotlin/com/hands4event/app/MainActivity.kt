package com.hands4event.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onResume() {
        super.onResume()
        crearCanalNotificaciones()
    }

    private fun crearCanalNotificaciones() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = NotificationChannel(
                "hands4events_notificaciones",
                "Notificaciones Hands4Events",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de eventos, mensajes y nóminas"
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(canal)
        }
    }
}
