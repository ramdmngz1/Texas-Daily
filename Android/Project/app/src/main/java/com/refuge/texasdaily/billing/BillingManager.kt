package com.refuge.texasdaily.billing

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class BillingManager(context: Context) : PurchasesUpdatedListener {

    private val _adsRemoved = MutableStateFlow(false)
    val adsRemoved: StateFlow<Boolean> = _adsRemoved

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage

    private var removeAdsProduct: ProductDetails? = null
    private var reconnectAttempts = 0

    private val billingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .build()

    private val connectionListener = object : BillingClientStateListener {
        override fun onBillingSetupFinished(result: BillingResult) {
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                reconnectAttempts = 0
                queryProductDetails()
                checkExistingPurchases()
            }
        }
        override fun onBillingServiceDisconnected() {
            val delay = (1000L * (1 shl reconnectAttempts.coerceAtMost(5)))
            reconnectAttempts++
            Handler(Looper.getMainLooper()).postDelayed({
                if (!billingClient.isReady) {
                    billingClient.startConnection(this)
                }
            }, delay)
        }
    }

    init {
        billingClient.startConnection(connectionListener)
    }

    fun endConnection() {
        billingClient.endConnection()
    }

    private fun queryProductDetails() {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(REMOVE_ADS_SKU)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
                )
            )
            .build()

        billingClient.queryProductDetailsAsync(params) { _, details ->
            removeAdsProduct = details.firstOrNull()
        }
    }

    private fun isVerifiedPurchase(purchase: Purchase): Boolean {
        return purchase.purchaseState == Purchase.PurchaseState.PURCHASED &&
            purchase.products.contains(REMOVE_ADS_SKU) &&
            !purchase.signature.isNullOrEmpty() &&
            !purchase.originalJson.isNullOrEmpty()
    }

    private fun checkExistingPurchases() {
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        ) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                val hasRemoveAds = purchases.any { isVerifiedPurchase(it) }
                _adsRemoved.value = hasRemoveAds
            }
        }
    }

    fun purchaseRemoveAds(activity: Activity) {
        val product = removeAdsProduct ?: run {
            _statusMessage.value = "Product not available. Please try again."
            return
        }
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(product)
                        .build()
                )
            )
            .build()
        billingClient.launchBillingFlow(activity, params)
    }

    fun restorePurchases() {
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.INAPP)
                .build()
        ) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                val hasRemoveAds = purchases.any { isVerifiedPurchase(it) }
                _adsRemoved.value = hasRemoveAds
                _statusMessage.value = if (hasRemoveAds) "Purchases restored." else "No purchases found to restore."
            } else {
                _statusMessage.value = "Could not check purchases. Please try again."
            }
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    if (isVerifiedPurchase(purchase)) {
                        _adsRemoved.value = true
                        _statusMessage.value = "Ads removed. Thank you!"
                        if (!purchase.isAcknowledged) {
                            acknowledgePurchase(purchase)
                        }
                    }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {}
            else -> _statusMessage.value = "Purchase failed. Please try again."
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        billingClient.acknowledgePurchase(params) {}
    }

    fun clearStatusMessage() { _statusMessage.value = null }

    companion object {
        const val REMOVE_ADS_SKU = "com.refuge.texasdaily.removead"
    }
}
