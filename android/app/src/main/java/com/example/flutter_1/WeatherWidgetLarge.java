package com.example.flutter_1;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.app.PendingIntent;
import android.content.Intent;
public class WeatherWidgetLarge extends AppWidgetProvider {
    private Bitmap createRangeBar(float minTemp, float maxTemp) {
        int width = 300;
        int height = 20;
        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);

        Paint bgPaint = new Paint();
        bgPaint.setColor(Color.parseColor("#3A3A3C"));
        bgPaint.setAntiAlias(true);
        canvas.drawRoundRect(new RectF(0, 0, width, height), 10, 10, bgPaint);

        float globalMin = 15f;
        float globalMax = 40f;
        float totalRange = globalMax - globalMin;

        float startPercent = (minTemp - globalMin) / totalRange;
        float endPercent = (maxTemp - globalMin) / totalRange;

        if (startPercent < 0) startPercent = 0;
        if (endPercent > 1) endPercent = 1;

        float startX = startPercent * width;
        float endX = endPercent * width;

        if (endX <= startX) endX = startX + 10;

        Paint barPaint = new Paint();
        barPaint.setShader(new LinearGradient(0, 0, width, 0,
                Color.parseColor("#FFD60A"), Color.parseColor("#FF9F0A"), Shader.TileMode.CLAMP));
        barPaint.setAntiAlias(true);

        canvas.drawRoundRect(new RectF(startX, 0, endX, height), 10, 10, barPaint);

        return bitmap;
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        SharedPreferences widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);

        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout_large);

            // Điều hướng vào app khi click vào
            Intent intent = new Intent(context, MainActivity.class);
            PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

            views.setTextViewText(R.id.widget_city_text, widgetData.getString("city_name", "HCM") + " 📍");
            views.setTextViewText(R.id.widget_temp_text, widgetData.getString("temperature", "--") + "°");
            views.setTextViewText(R.id.widget_desc_text, widgetData.getString("description", ""));
            views.setTextViewText(R.id.widget_icon_emoji, widgetData.getString("weather_emoji", ""));
            views.setTextViewText(R.id.widget_hl_text, widgetData.getString("high_low", ""));

            int[] hTimeIds = {R.id.hourly_time_0, R.id.hourly_time_1, R.id.hourly_time_2, R.id.hourly_time_3, R.id.hourly_time_4, R.id.hourly_time_5};
            int[] hEmojiIds = {R.id.hourly_emoji_0, R.id.hourly_emoji_1, R.id.hourly_emoji_2, R.id.hourly_emoji_3, R.id.hourly_emoji_4, R.id.hourly_emoji_5};
            int[] hTempIds = {R.id.hourly_temp_0, R.id.hourly_temp_1, R.id.hourly_temp_2, R.id.hourly_temp_3, R.id.hourly_temp_4, R.id.hourly_temp_5};

            for (int i = 0; i < 6; i++) {
                String time = widgetData.getString("hourly_time_" + i, "--");
                String temp = widgetData.getString("hourly_temp_" + i, "--");
                String emoji = widgetData.getString("hourly_emoji_" + i, "");

                views.setTextViewText(hTimeIds[i], time);
                views.setTextViewText(hEmojiIds[i], emoji);
                views.setTextViewText(hTempIds[i], temp + "°");
            }

            int[] dDayIds = {R.id.daily_day_0, R.id.daily_day_1, R.id.daily_day_2, R.id.daily_day_3, R.id.daily_day_4};
            int[] dIconIds = {R.id.daily_icon_0, R.id.daily_icon_1, R.id.daily_icon_2, R.id.daily_icon_3, R.id.daily_icon_4};
            int[] dMinIds = {R.id.daily_min_0, R.id.daily_min_1, R.id.daily_min_2, R.id.daily_min_3, R.id.daily_min_4};
            int[] dMaxIds = {R.id.daily_max_0, R.id.daily_max_1, R.id.daily_max_2, R.id.daily_max_3, R.id.daily_max_4};

            int[] dBarIds = {R.id.daily_bar_0, R.id.daily_bar_1, R.id.daily_bar_2, R.id.daily_bar_3, R.id.daily_bar_4};

            for (int i = 0; i < 5; i++) {
                String day = widgetData.getString("daily_day_" + i, "--");
                String minStr = widgetData.getString("daily_min_" + i, "0");
                String maxStr = widgetData.getString("daily_max_" + i, "0");
                String icon = widgetData.getString("daily_icon_" + i, "");

                float minT = 0;
                float maxT = 0;
                try {
                    minT = Float.parseFloat(minStr);
                    maxT = Float.parseFloat(maxStr);
                } catch (Exception e) {}

                views.setTextViewText(dDayIds[i], day);
                views.setTextViewText(dMinIds[i], minStr + "°");
                views.setTextViewText(dMaxIds[i], maxStr + "°");
                views.setTextViewText(dIconIds[i], icon);

                views.setImageViewBitmap(dBarIds[i], createRangeBar(minT, maxT));
            }

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}