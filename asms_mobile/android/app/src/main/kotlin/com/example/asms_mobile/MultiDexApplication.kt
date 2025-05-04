package com.example.asms_mobile

import android.app.Application
import android.content.Context
import androidx.multidex.MultiDex

class MultiDexApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
    // Add any application-wide initialization code here if needed
} 