package com.yakityonet.yakit_yonet

import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import java.io.File

object WidgetHelper {

    private const val TAG = "WidgetHelper"

    data class WidgetData(
        val vehicleName: String,
        val fuelType: String,
        val costPerKm: String,
        val litersPer100: String,
        val totalKm: String,
        val imagePath: String,
    )

    fun readData(prefs: SharedPreferences): WidgetData {
        android.util.Log.d(TAG, "Reading widget data from SharedPreferences")
        android.util.Log.d(TAG, "All preferences keys: ${prefs.all.keys}")
        
        val data = WidgetData(
            vehicleName = prefs.getString("vehicle_name", "Araç Seçilmedi") ?: "Araç Seçilmedi",
            fuelType = prefs.getString("fuel_type", "") ?: "",
            costPerKm = prefs.getString("cost_per_km", "—") ?: "—",
            litersPer100 = prefs.getString("liters_per_100", "—") ?: "—",
            totalKm = prefs.getString("vehicle_km", "—") ?: "—",
            imagePath = prefs.getString("vehicle_image_path", "") ?: "",
        )
        
        android.util.Log.d(TAG, "Read data: $data")
        return data
    }

    /**
     * Creates a plain rounded placeholder bitmap (gray fill).
     * Used instead of setImageViewResource() which doesn't support vectors in RemoteViews on API < 31.
     */
    fun createPlaceholderBitmap(sizePx: Int, radiusPx: Int): Bitmap {
        val out = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.parseColor("#F5F5F4")
        }
        canvas.drawRoundRect(RectF(0f, 0f, sizePx.toFloat(), sizePx.toFloat()), radiusPx.toFloat(), radiusPx.toFloat(), paint)
        return out
    }

    /**
     * Loads, scales and rounds the vehicle photo.
     * Returns null when the path is empty or the file doesn't exist.
     * The returned bitmap fills the requested [sizePx] square with rounded corners ([radiusPx]).
     */
    fun loadRoundedBitmap(path: String, sizePx: Int, radiusPx: Int): Bitmap? {
        if (path.isEmpty() || !File(path).exists()) return null
        return try {
            // 1 — probe dimensions without allocating memory
            val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, opts)
            if (opts.outWidth <= 0 || opts.outHeight <= 0) return null

            // 2 — decode at appropriate sample size
            opts.inSampleSize = calcSampleSize(opts, sizePx, sizePx)
            opts.inJustDecodeBounds = false
            val src = BitmapFactory.decodeFile(path, opts) ?: return null

            // 3 — center-crop to square then round
            roundCrop(src, radiusPx, sizePx)
        } catch (_: Exception) {
            null
        }
    }

    private fun calcSampleSize(opts: BitmapFactory.Options, rw: Int, rh: Int): Int {
        var sample = 1
        val halfH = opts.outHeight / 2
        val halfW = opts.outWidth / 2
        while (halfH / sample >= rh && halfW / sample >= rw) sample *= 2
        return sample
    }

    private fun roundCrop(src: Bitmap, radiusPx: Int, sizePx: Int): Bitmap {
        // Step 1: center-crop source to square
        val srcSize = minOf(src.width, src.height)
        val x = (src.width - srcSize) / 2
        val y = (src.height - srcSize) / 2
        val squared = Bitmap.createBitmap(src, x, y, srcSize, srcSize)

        // Step 2: scale to target size
        val scaled = Bitmap.createScaledBitmap(squared, sizePx, sizePx, true)

        // Step 3: apply rounded mask
        val out = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val maskPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            // White fill to create opaque mask region
            android.graphics.Color.WHITE.let { color = it }
        }
        canvas.drawRoundRect(RectF(0f, 0f, sizePx.toFloat(), sizePx.toFloat()), radiusPx.toFloat(), radiusPx.toFloat(), maskPaint)
        maskPaint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(scaled, 0f, 0f, maskPaint)

        return out
    }
}
