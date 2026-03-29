package com.yakityonet.yakit_yonet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FuelWidgetSmallProvider : HomeWidgetProvider() {
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

                    val bitmap = WidgetHelper.loadRoundedBitmap(data.imagePath, 132, 22)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.iv_vehicle_thumb_small, bitmap)
                    } else {
                        setImageViewResource(R.id.iv_vehicle_thumb_small, R.drawable.ic_car_placeholder)
                    }

                    setOnClickPendingIntent(R.id.btn_add_fuel_small, pendingIntent)
                    setOnClickPendingIntent(R.id.tv_vehicle_name_small, pendingIntent)
                    setOnClickPendingIntent(R.id.iv_vehicle_thumb_small, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (_: Exception) {
                val fallback = RemoteViews(context.packageName, R.layout.fuel_widget_small_layout)
                fallback.setTextViewText(R.id.tv_vehicle_name_small, data.vehicleName)
                fallback.setOnClickPendingIntent(R.id.btn_add_fuel_small, pendingIntent)
                appWidgetManager.updateAppWidget(widgetId, fallback)
            }
        }
    }
}
