package com.example.flutter_1;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.app.PendingIntent;
import android.content.Intent;
public class WeatherWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        SharedPreferences widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);

        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);

            // Điều hướng vào app khi click vào
            Intent intent = new Intent(context, MainActivity.class);
            PendingIntent pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

            String city = widgetData.getString("city_name", "Đang tải...");
            String temp = widgetData.getString("temperature", "--");
            String desc = widgetData.getString("description", "Vui lòng mở app");
            String hl = widgetData.getString("high_low", "--/--");
            String emoji = widgetData.getString("weather_emoji", "🌤️");

            views.setTextViewText(R.id.widget_city_text, city + " 📍");
            views.setTextViewText(R.id.widget_temp_text, temp + "°");
            views.setTextViewText(R.id.widget_desc_text, desc);
            views.setTextViewText(R.id.widget_hl_text, hl);
            views.setTextViewText(R.id.widget_icon_emoji, emoji);

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
