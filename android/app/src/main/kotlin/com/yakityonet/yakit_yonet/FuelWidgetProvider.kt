package com.yakityonet.yakit_yonet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FuelWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = WidgetHelper.readData(widgetData)
        // URI makes Flutter detect the widget tap and open add-fuel screen
        val launchUri = Uri.parse("yakityonet://widget/add-fuel")
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, launchUri
        )

        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.fuel_widget_layout).apply {
                    setTextViewText(R.id.tv_vehicle_name, data.vehicleName)
                    setTextViewText(R.id.tv_fuel_type, data.fuelType)
                    setTextViewText(R.id.tv_cost_per_km, data.costPerKm)
                    setTextViewText(R.id.tv_liters_per100, data.litersPer100)
                    setTextViewText(R.id.tv_total_km, data.totalKm)

                    val bitmap = WidgetHelper.loadRoundedBitmap(data.imagePath, 156, 28)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.iv_vehicle_thumb, bitmap)
                    } else {
                        setImageViewResource(R.id.iv_vehicle_thumb, R.drawable.ic_car_placeholder)
                    }

                    setOnClickPendingIntent(R.id.btn_add_fuel, pendingIntent)
                    setOnClickPendingIntent(R.id.tv_vehicle_name, pendingIntent)
                    setOnClickPendingIntent(R.id.iv_vehicle_thumb, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (_: Exception) {
                // On any failure, show minimal safe layout with defaults
                val fallback = RemoteViews(context.packageName, R.layout.fuel_widget_layout)
                fallback.setTextViewText(R.id.tv_vehicle_name, data.vehicleName)
                fallback.setOnClickPendingIntent(R.id.btn_add_fuel, pendingIntent)
                appWidgetManager.updateAppWidget(widgetId, fallback)
            }
        }
    }
}
