package com.drivemate.auto

import android.content.Intent
import androidx.car.app.Screen
import androidx.car.app.Session

class DriveMateCarSession : Session() {

    override fun onCreateScreen(intent: Intent): Screen {
        return DriveMateCarScreen(carContext)
    }
}
