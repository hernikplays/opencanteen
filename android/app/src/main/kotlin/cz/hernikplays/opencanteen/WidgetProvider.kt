package cz.hernikplays.opencanteen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                setTextViewText(R.id.obed, widgetData.getString("_obed", "Nic"))

                // Pending intent to update counter on button click
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
                        Uri.parse("myAppWidget://update"))
                setOnClickPendingIntent(R.id.bt_update, backgroundIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}