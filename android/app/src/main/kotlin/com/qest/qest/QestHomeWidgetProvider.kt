package com.qest.qest

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class QestHomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.qest_home_widget)

            views.setTextViewText(R.id.next_title,
                widgetData.getString("next_title", "—"))
            views.setTextViewText(R.id.next_amount,
                widgetData.getString("next_amount", ""))
            views.setTextViewText(R.id.next_due,
                widgetData.getString("next_due", ""))
            views.setTextViewText(R.id.overdue_count,
                "${widgetData.getInt("overdue_count", 0)} overdue")
            views.setTextViewText(R.id.today_count,
                "${widgetData.getInt("today_count", 0)} today")

            val launchIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(android.R.id.content, launchIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
