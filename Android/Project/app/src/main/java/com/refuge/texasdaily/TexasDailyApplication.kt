package com.refuge.texasdaily

import android.app.Application
import com.google.android.gms.ads.MobileAds

class TexasDailyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileAds.initialize(this)
    }
}
