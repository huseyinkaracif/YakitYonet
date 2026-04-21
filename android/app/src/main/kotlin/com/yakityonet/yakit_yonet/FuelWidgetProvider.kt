package com.yakityonet.yakit_yonet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FuelWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "FuelWidgetProvider"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        Log.d(TAG, "=== onUpdate START ===")
        val data = WidgetHelper.readData(widgetData)
        Log.d(TAG, "onUpdate called with widgetIds: ${appWidgetIds.toList()}, data: $data")
        Log.d(TAG, "Layout resource: fuel_widget_layout = ${R.layout.fuel_widget_layout}")
        
        // URI makes Flutter detect the widget tap and open add-fuel screen
        val launchUri = Uri.parse("yakityonet://widget/add-fuel")
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, launchUri
        )
        Log.d(TAG, "Created pending intent for URI: $launchUri")

        appWidgetIds.forEach { widgetId ->
            try {
                Log.d(TAG, "=== Updating widgetId=$widgetId ===")
                val views = RemoteViews(context.packageName, R.layout.fuel_widget_layout)
                Log.d(TAG, "Created RemoteViews with package: ${context.packageName}")
                
                views.setTextViewText(R.id.tv_vehicle_name, data.vehicleName)
                views.setTextViewText(R.id.tv_fuel_type, data.fuelType)
                views.setTextViewText(R.id.tv_cost_per_km, data.costPerKm)
                views.setTextViewText(R.id.tv_liters_per100, data.litersPer100)
                views.setTextViewText(R.id.tv_total_km, data.totalKm)
                Log.d(TAG, "Set text views: name=${data.vehicleName}, fuel=${data.fuelType}, cost=${data.costPerKm}")

                // Load vehicle image or placeholder
                try {
                    val bitmap = WidgetHelper.loadRoundedBitmap(data.imagePath, 156, 28)
                        ?: WidgetHelper.createPlaceholderBitmap(156, 28)
                    views.setImageViewBitmap(R.id.iv_vehicle_thumb, bitmap)
                    Log.d(TAG, "Set image bitmap successfully")
                } catch (e: Exception) {
                    Log.w(TAG, "Image load failed, using placeholder", e)
                    views.setImageViewBitmap(
                        R.id.iv_vehicle_thumb,
                        WidgetHelper.createPlaceholderBitmap(156, 28)
                    )
                }

                views.setOnClickPendingIntent(R.id.btn_add_fuel, pendingIntent)
                views.setOnClickPendingIntent(R.id.tv_vehicle_name, pendingIntent)
                views.setOnClickPendingIntent(R.id.iv_vehicle_thumb, pendingIntent)
                Log.d(TAG, "Set pending intents")

                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d(TAG, "=== Widget updated successfully for widgetId=$widgetId ===")
            } catch (e: Exception) {
                Log.e(TAG, "=== Widget update FAILED for widgetId=$widgetId ===", e)
                // On any failure, show minimal safe layout with defaults
                try {
                    val fallback = RemoteViews(context.packageName, R.layout.fuel_widget_layout)
                    fallback.setTextViewText(R.id.tv_vehicle_name, data.vehicleName)
                    fallback.setOnClickPendingIntent(R.id.btn_add_fuel, pendingIntent)
                    appWidgetManager.updateAppWidget(widgetId, fallback)
                    Log.d(TAG, "Fallback widget updated for widgetId=$widgetId")
                } catch (e2: Exception) {
                    Log.e(TAG, "Fallback widget update also failed", e2)
                }
            }
        }
        Log.d(TAG, "=== onUpdate END ===")
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
