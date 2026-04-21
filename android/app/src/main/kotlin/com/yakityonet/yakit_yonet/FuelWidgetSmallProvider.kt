package com.yakityonet.yakit_yonet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FuelWidgetSmallProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "FuelWidgetSmallProvider"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = WidgetHelper.readData(widgetData)
        val launchUri = Uri.parse("yakityonet://widget/add-fuel")
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, launchUri
        )

        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.fuel_widget_small_layout).apply {
                    setTextViewText(R.id.tv_vehicle_name_small, data.vehicleName)
                    setTextViewText(R.id.tv_fuel_type_small, data.fuelType)
                    setTextViewText(R.id.tv_cost_per_km_small, data.costPerKm)
                    setTextViewText(R.id.tv_liters_per100_small, data.litersPer100)
                    setTextViewText(R.id.tv_total_km_small, data.totalKm)

                    // Load vehicle image or placeholder
                    try {
                        val bitmap = WidgetHelper.loadRoundedBitmap(data.imagePath, 132, 22)
                            ?: WidgetHelper.createPlaceholderBitmap(132, 22)
                        setImageViewBitmap(R.id.iv_vehicle_thumb_small, bitmap)
                    } catch (e: Exception) {
                        Log.w(TAG, "Image load failed, using placeholder", e)
                        setImageViewBitmap(
                            R.id.iv_vehicle_thumb_small,
                            WidgetHelper.createPlaceholderBitmap(132, 22)
                        )
                    }

                    setOnClickPendingIntent(R.id.btn_add_fuel_small, pendingIntent)
                    setOnClickPendingIntent(R.id.tv_vehicle_name_small, pendingIntent)
                    setOnClickPendingIntent(R.id.iv_vehicle_thumb_small, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "Widget update failed for widgetId=$widgetId", e)
                // On any failure, show minimal safe layout with defaults
                try {
                    val fallback = RemoteViews(context.packageName, R.layout.fuel_widget_small_layout)
                    fallback.setTextViewText(R.id.tv_vehicle_name_small, data.vehicleName)
                    fallback.setOnClickPendingIntent(R.id.btn_add_fuel_small, pendingIntent)
                    appWidgetManager.updateAppWidget(widgetId, fallback)
                } catch (e2: Exception) {
                    Log.e(TAG, "Fallback widget update also failed", e2)
                }
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "Widget enabled")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "Widget disabled")
    }
}
