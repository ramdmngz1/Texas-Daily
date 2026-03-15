package com.refuge.texasdaily.ui.components

import android.os.Build
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError
import com.refuge.texasdaily.BuildConfig

private const val TAG = "TexasDailyAds"
private const val PROD_BANNER_AD_UNIT_ID = "ca-app-pub-2130345513930124/7290959047"
private const val TEST_BANNER_AD_UNIT_ID = "ca-app-pub-3940256099942544/6300978111"

private fun isEmulator(): Boolean {
    val fingerprint = Build.FINGERPRINT.lowercase()
    return fingerprint.contains("generic") ||
        fingerprint.contains("emulator") ||
        Build.MODEL.contains("Emulator", ignoreCase = true) ||
        Build.MANUFACTURER.contains("Genymotion", ignoreCase = true)
}

private fun resolvedBannerUnitId(): String {
    return if (BuildConfig.DEBUG && isEmulator()) TEST_BANNER_AD_UNIT_ID else PROD_BANNER_AD_UNIT_ID
}

@Composable
fun BannerAdView() {
    val adUnitId = resolvedBannerUnitId()
    AndroidView(
        factory = { context ->
            AdView(context).apply {
                setAdSize(AdSize.BANNER)
                this.adUnitId = adUnitId
                adListener = object : AdListener() {
                    override fun onAdLoaded() {
                        Log.d(TAG, "Banner loaded: $adUnitId")
                    }

                    override fun onAdFailedToLoad(error: LoadAdError) {
                        Log.w(TAG, "Banner failed: code=${error.code} message=${error.message}")
                    }
                }
                loadAd(AdRequest.Builder().build())
            }
        }
    )
}
