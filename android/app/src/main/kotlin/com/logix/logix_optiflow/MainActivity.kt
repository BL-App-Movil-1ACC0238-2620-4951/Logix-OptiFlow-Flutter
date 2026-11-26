package com.logix.logix_optiflow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal de los push del paciente (el mismo de la app Kotlin); existe desde Android 8.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel =
            NotificationChannel("optiflow_patient", "Citas y pedidos", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Recordatorios de citas, avisos de tus lentes y encuestas"
            }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
