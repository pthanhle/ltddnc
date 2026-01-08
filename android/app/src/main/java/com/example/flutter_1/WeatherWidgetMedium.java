package com.example.flutter_1;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.app.PendingIntent;
import android.content.Intent;
public class WeatherWidgetMedium extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        SharedPreferences widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);

        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout_medium);

            // Điều hướng vào app khi click vào
            Intent intent = new Intent(context, MainActivity.class);
            PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

            views.setTextViewText(R.id.widget_city_text, widgetData.getString("city_name", "Loading...") + " 📍");
            views.setTextViewText(R.id.widget_temp_text, widgetData.getString("temperature", "--") + "°");
            views.setTextViewText(R.id.widget_icon_emoji, widgetData.getString("weather_emoji", ""));
            views.setTextViewText(R.id.widget_desc_text, widgetData.getString("description", ""));
            views.setTextViewText(R.id.widget_hl_text, widgetData.getString("high_low", ""));

            for (int i = 0; i < 6; i++) {
                String time = widgetData.getString("hourly_time_" + i, "--");
                String temp = widgetData.getString("hourly_temp_" + i, "--");
                String emoji = widgetData.getString("hourly_emoji_" + i, "");

                int timeId = context.getResources().getIdentifier("hourly_time_" + i, "id", context.getPackageName());
                int tempId = context.getResources().getIdentifier("hourly_temp_" + i, "id", context.getPackageName());
                int emojiId = context.getResources().getIdentifier("hourly_emoji_" + i, "id", context.getPackageName());

                views.setTextViewText(timeId, time);
                views.setTextViewText(emojiId, emoji);
                views.setTextViewText(tempId, temp + "°");
            }

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}