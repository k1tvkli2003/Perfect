package com.k1tvkli2003.perfect

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Calendar
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

/**
 * Native Android rendering for Perfect Today.
 *
 * Flutter publishes a small, versioned projection into HomeWidgetPreferences.
 * This provider never opens Drift/SQLite itself: task actions are first stored
 * as a bounded native replay queue and then applied by the Dart background
 * callback using the normal local outbox. That separation avoids two writers
 * racing over the planner database while still giving the home screen instant
 * visual feedback.
 */
class PerfectTodayWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { id -> updateOne(context, appWidgetManager, id, widgetData) }
    maintainDayBoundary(context, widgetData)
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    updateOne(
        context,
        appWidgetManager,
        appWidgetId,
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE),
    )
    maintainDayBoundary(
        context,
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE),
    )
  }

  override fun onDisabled(context: Context) {
    PerfectTodayWidgetRefreshReceiver.cancel(context)
    super.onDisabled(context)
  }

  companion object {
    const val ACTION_WIDGET_TASK = "com.k1tvkli2003.perfect.WIDGET_TASK"
    const val EXTRA_TASK_ACTION = "perfect_widget_task_action"
    const val EXTRA_ENTITY_ID = "perfect_widget_entity_id"
    const val EXTRA_COMPACT_LAYOUT = "perfect_widget_compact_layout"
    private const val PREFS_NAME = "HomeWidgetPreferences"

    fun refresh(context: Context) {
      val manager = AppWidgetManager.getInstance(context)
      val ids = manager.getAppWidgetIds(
          ComponentName(context, PerfectTodayWidgetProvider::class.java),
      )
      val data = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      ids.forEach { id -> updateOne(context, manager, id, data) }
      if (ids.isNotEmpty()) manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_task_list)
      if (ids.isNotEmpty()) maintainDayBoundary(context, data)
    }

    private fun updateOne(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        data: SharedPreferences,
    ) {
      val snapshot = PerfectTodayWidgetStore.read(data)
      val views =
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ launchers can select the best composition directly
            // from this responsive map, including after rotation without
            // waking the provider. Narrow/tall and wide/short widgets no longer
            // inherit a layout chosen from an ambiguous min/max size range.
            RemoteViews(
                linkedMapOf(
                    SizeF(110f, 110f) to createViews(
                        context,
                        appWidgetId,
                        snapshot,
                        R.layout.perfect_today_widget_small,
                    ),
                    SizeF(110f, 180f) to createViews(
                        context,
                        appWidgetId,
                        snapshot,
                        R.layout.perfect_today_widget_tall,
                    ),
                    SizeF(220f, 110f) to createViews(
                        context,
                        appWidgetId,
                        snapshot,
                        R.layout.perfect_today_widget_wide,
                    ),
                    SizeF(260f, 220f) to createViews(
                        context,
                        appWidgetId,
                        snapshot,
                        R.layout.perfect_today_widget_large,
                    ),
                ),
            )
          } else {
            createViews(
                context,
                appWidgetId,
                snapshot,
                layoutFor(manager.getAppWidgetOptions(appWidgetId)),
            )
          }
      manager.updateAppWidget(appWidgetId, views)
      manager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_task_list)
    }

    private fun createViews(
        context: Context,
        appWidgetId: Int,
        snapshot: PerfectTodayWidgetStore.Snapshot,
        layout: Int,
    ): RemoteViews {
      val isStale = snapshot.ownerId.isNotBlank() && !snapshot.isCurrentDay
      val visibleItems = if (isStale) emptyList() else snapshot.items
      return RemoteViews(context.packageName, layout).apply {
        setTextViewText(
            R.id.widget_date,
            if (isStale) "Today" else snapshot.dateLabel.ifBlank { "Today" },
        )
        setTextViewText(
            R.id.widget_freshness,
            when {
              isStale -> "Refreshing…"
              visibleItems.isEmpty() -> ""
              else -> "Local & ready"
            },
        )
        setTextViewText(
            R.id.widget_orbit_hint,
            when {
              isStale -> "Preparing your new orbit"
              visibleItems.size == 0 -> "Your day, in orbit"
              visibleItems.size == 1 -> "1 task in orbit"
              else -> "${visibleItems.size} tasks in orbit · scroll all"
            },
        )
        setTextViewText(
            R.id.widget_empty,
            if (isStale) "Refreshing today…" else "Your day is ready",
        )
        val hasItems = visibleItems.isNotEmpty()
        setViewVisibility(R.id.widget_task_list, if (hasItems) View.VISIBLE else View.GONE)
        setViewVisibility(R.id.widget_empty, if (hasItems) View.GONE else View.VISIBLE)

        val serviceIntent = Intent(context, PerfectTodayWidgetService::class.java).apply {
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
          putExtra(
              EXTRA_COMPACT_LAYOUT,
              layout == R.layout.perfect_today_widget_small ||
                  layout == R.layout.perfect_today_widget_tall,
          )
          // Widget hosts cache adapters by intent identity; versioning the URI
          // forces a fresh factory after each local projection/action.
          val sizeClass = when (layout) {
            R.layout.perfect_today_widget_small -> "small"
            R.layout.perfect_today_widget_tall -> "tall"
            R.layout.perfect_today_widget_large -> "large"
            else -> "wide"
          }
          setData(
              Uri.parse(
                  "perfect://today-widget/$appWidgetId/${snapshot.updatedAtMillis}/$sizeClass",
              ),
          )
        }
        @Suppress("DEPRECATION")
        setRemoteAdapter(R.id.widget_task_list, serviceIntent)
        setEmptyView(R.id.widget_task_list, R.id.widget_empty)

        val taskTemplateIntent = Intent(context, PerfectTodayWidgetActionReceiver::class.java).apply {
          action = ACTION_WIDGET_TASK
          setData(Uri.parse("perfect://today-widget/action/$appWidgetId"))
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val taskTemplate = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            taskTemplateIntent,
            // Collection rows contribute the entity/action extras through
            // setOnClickFillInIntent(), so this explicit, package-local
            // template must remain mutable for the launcher to merge them.
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
        setPendingIntentTemplate(R.id.widget_task_list, taskTemplate)

        val openToday = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("perfect://planner/today"),
        )
        setOnClickPendingIntent(R.id.widget_open_today, openToday)
        val quickAddIntent = Intent(context, PerfectWidgetQuickAddActivity::class.java).apply {
          setData(Uri.parse("perfect://today-widget/quick-add/$appWidgetId"))
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val quickAdd = PendingIntent.getActivity(
            context,
            100_000 + appWidgetId,
            quickAddIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        setOnClickPendingIntent(R.id.widget_quick_add, quickAdd)
        if (layout == R.layout.perfect_today_widget_large) {
          setOnClickPendingIntent(R.id.widget_open_today_footer, openToday)
        }
      }
    }

    private fun maintainDayBoundary(context: Context, data: SharedPreferences) {
      PerfectTodayWidgetRefreshReceiver.schedule(context)
      val snapshot = PerfectTodayWidgetStore.read(data)
      if (snapshot.ownerId.isNotBlank() && !snapshot.isCurrentDay) {
        PerfectTodayWidgetRefreshReceiver.dispatch(context)
      }
    }

    private fun layoutFor(options: Bundle): Int {
      val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
      val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
      return when {
        width >= 260 && height >= 220 -> R.layout.perfect_today_widget_large
        width >= 220 -> R.layout.perfect_today_widget_wide
        height >= 180 -> R.layout.perfect_today_widget_tall
        else -> R.layout.perfect_today_widget_small
      }
    }
  }
}

/**
 * A package-private alarm target refreshes Today even when the app process is
 * absent. Android's 30-minute widget update remains the recovery backstop.
 */
class PerfectTodayWidgetRefreshReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (!hasWidgets(context)) {
      cancel(context)
      return
    }
    dispatch(context)
    schedule(context)
  }

  companion object {
    private const val REQUEST_CODE = 7182

    fun schedule(context: Context) {
      val nextDay = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 1)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
      }
      val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
      alarm.setAndAllowWhileIdle(
          AlarmManager.RTC_WAKEUP,
          nextDay.timeInMillis,
          pendingIntent(context),
      )
    }

    fun cancel(context: Context) {
      val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
      alarm.cancel(pendingIntent(context))
    }

    fun dispatch(context: Context) {
      val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
      val ownerId = prefs.getString(PerfectTodayWidgetStore.OWNER_ID_KEY, null)
          ?.trim()
          .orEmpty()
      val token = prefs.getString(PerfectTodayWidgetStore.INTERACTION_TOKEN_KEY, null)
          ?.trim()
          .orEmpty()
      if (ownerId.isEmpty() || token.isEmpty()) return
      val uri = Uri.Builder()
          .scheme("perfect")
          .authority("widget-refresh")
          .appendQueryParameter("owner_id", ownerId)
          .appendQueryParameter("token", token)
          .build()
      try {
        HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
      } catch (_: PendingIntent.CanceledException) {
        // The periodic provider update requests another refresh.
      }
    }

    private fun hasWidgets(context: Context): Boolean =
        AppWidgetManager.getInstance(context).getAppWidgetIds(
            ComponentName(context, PerfectTodayWidgetProvider::class.java),
        ).isNotEmpty()

    private fun pendingIntent(context: Context): PendingIntent {
      val intent = Intent(context, PerfectTodayWidgetRefreshReceiver::class.java)
          .setAction("com.k1tvkli2003.perfect.WIDGET_DAY_ROLLOVER")
      return PendingIntent.getBroadcast(
          context,
          REQUEST_CODE,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
    }
  }
}

/** Receives only the explicit PendingIntent created by this package. */
class PerfectTodayWidgetActionReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != PerfectTodayWidgetProvider.ACTION_WIDGET_TASK) return
    if (intent.getStringExtra(PerfectTodayWidgetProvider.EXTRA_TASK_ACTION) != "cycle") return
    val entityId = intent.getStringExtra(PerfectTodayWidgetProvider.EXTRA_ENTITY_ID)
        ?.trim()
        .orEmpty()
    if (entityId.isEmpty()) return

    val action = PerfectTodayWidgetStore.cycle(context, entityId)
    if (action == null) {
      // A tap can race midnight before the launcher receives its periodic
      // update. Re-render immediately: stale rows are hidden and a tokenized
      // background refresh is dispatched instead of leaving a dead control.
      PerfectTodayWidgetProvider.refresh(context)
      return
    }
    PerfectTodayWidgetProvider.refresh(context)

    // WorkManager serializes the Dart callbacks. If the process cannot start
    // now, the native replay queue survives and is replayed on the next app
    // foreground without turning a user tap into data loss.
    val uri = action.toBackgroundUri(
        context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .getString(PerfectTodayWidgetStore.INTERACTION_TOKEN_KEY, null),
    ) ?: return
    try {
      HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
    } catch (_: PendingIntent.CanceledException) {
      // Queue retention is the recovery mechanism.
    }
  }
}

/** Android's supported collection surface: it scrolls natively in the host. */
class PerfectTodayWidgetService : RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
      PerfectTodayRemoteViewsFactory(
          applicationContext,
          intent.getBooleanExtra(
              PerfectTodayWidgetProvider.EXTRA_COMPACT_LAYOUT,
              false,
          ),
      )
}

private class PerfectTodayRemoteViewsFactory(
    private val context: Context,
    private val compact: Boolean,
) : RemoteViewsService.RemoteViewsFactory {
  private var items: List<PerfectTodayWidgetStore.Item> = emptyList()

  override fun onCreate() = Unit

  override fun onDataSetChanged() {
    val snapshot = PerfectTodayWidgetStore.read(
        context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE),
    )
    items = if (snapshot.isCurrentDay) snapshot.items else emptyList()
  }

  override fun onDestroy() {
    items = emptyList()
  }

  override fun getCount(): Int = items.size

  override fun getViewAt(position: Int): RemoteViews {
    val itemLayout =
        if (compact) R.layout.perfect_today_widget_item_compact
        else R.layout.perfect_today_widget_item
    if (position !in items.indices) {
      return RemoteViews(context.packageName, itemLayout)
    }
    val item = items[position]
    return RemoteViews(context.packageName, itemLayout).apply {
      setTextViewText(R.id.widget_item_title, item.title)
      setImageViewResource(R.id.widget_item_check, item.iconResource)
      if (!compact) {
        setTextViewText(R.id.widget_item_meta, item.time)
        setTextViewText(R.id.widget_item_state, item.stateLabel)
        setTextColor(R.id.widget_item_state, Color.parseColor(item.stateColor))
      }
      setContentDescription(
          R.id.widget_item_check,
          "${item.title}. ${item.stateLabel}. Tap to cycle outcome.",
      )
      val cycleIntent = Intent().apply {
        putExtra(PerfectTodayWidgetProvider.EXTRA_TASK_ACTION, "cycle")
        putExtra(PerfectTodayWidgetProvider.EXTRA_ENTITY_ID, item.id)
      }
      setOnClickFillInIntent(R.id.widget_item_check, cycleIntent)
    }
  }

  override fun getLoadingView(): RemoteViews? = null

  override fun getViewTypeCount(): Int = 1

  override fun getItemId(position: Int): Long =
      items.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

  override fun hasStableIds(): Boolean = true
}

internal object PerfectTodayWidgetStore {
  const val SNAPSHOT_KEY = "perfect_today_widget_snapshot_v1"
  const val PENDING_ACTIONS_KEY = "perfect_today_widget_actions_v1"
  const val ACKNOWLEDGED_ACTIONS_KEY = "perfect_today_widget_acknowledged_actions_v1"
  const val PENDING_QUICK_ADDS_KEY = "perfect_today_widget_quick_adds_v1"
  const val ACKNOWLEDGED_QUICK_ADDS_KEY =
      "perfect_today_widget_acknowledged_quick_adds_v1"
  const val INTERACTION_TOKEN_KEY = "perfect_today_widget_token_v1"
  const val OWNER_ID_KEY = "perfect_today_widget_owner_v1"
  private const val ACTION_SEQUENCE_KEY = "perfect_today_widget_action_sequence_v1"
  private const val QUEUE_OVERFLOW_COUNT_KEY = "perfect_today_widget_queue_overflow_v1"
  // This is a last-resort storage guard, not an eviction policy. Repeated taps
  // compact to one absolute state per owner/entity/day, and Dart acknowledgments
  // are removed on the next native write. A new tap is refused before changing
  // the optimistic snapshot if 4096 distinct, unacknowledged outcomes remain.
  private const val MAX_ACTIONS = 4096
  private const val MAX_QUICK_ADDS = 256

  data class Snapshot(
      val ownerId: String,
      val dateKey: String,
      val dateLabel: String,
      val updatedAtMillis: Long,
      val items: List<Item>,
  ) {
    val isCurrentDay: Boolean
      get() = dateKey == LocalDate.now().toString()
  }

  data class Item(
      val id: String,
      val kind: String,
      val title: String,
      val time: String,
      val state: String,
      val percent: Int,
      val accent: String,
  ) {
    val iconResource: Int
      get() = when (state) {
        "completed" -> R.drawable.perfect_widget_status_completed
        "missed" -> R.drawable.perfect_widget_status_missed
        "partial" -> R.drawable.perfect_widget_status_partial
        else -> R.drawable.perfect_widget_status_pending
      }

    val stateLabel: String
      get() = when (state) {
        "completed" -> "Done"
        "missed" -> "Not done"
        "partial" -> "$percent%"
        else -> "Empty"
      }

    val stateColor: String
      get() = when (state) {
        "completed" -> "#FF7EC99B"
        "missed" -> "#FFC8505A"
        "partial" -> "#FFA79ADD"
        else -> when (accent) {
          "mint" -> "#FF7EC99B"
          "lilac" -> "#FFA79ADD"
          else -> "#FFFFA34D"
        }
      }
  }

  data class Action(
      val id: String,
      val ownerId: String,
      val entityId: String,
      val kind: String,
      val state: String,
      val percent: Int,
      val localDay: String,
      val occurredAt: String,
      val queueSequence: Long,
  ) {
    fun toJson(): JSONObject = JSONObject().apply {
      put("id", id)
      put("owner_id", ownerId)
      put("entity_id", entityId)
      put("kind", kind)
      put("state", state)
      put("progress_percent", percent)
      put("local_day", localDay)
      put("occurred_at", occurredAt)
      put("queue_sequence", queueSequence)
    }

    fun toBackgroundUri(token: String?): Uri? {
      if (token.isNullOrBlank()) return null
      return Uri.Builder()
          .scheme("perfect")
          .authority("widget-action")
          .appendQueryParameter("id", id)
          .appendQueryParameter("owner_id", ownerId)
          .appendQueryParameter("entity_id", entityId)
          .appendQueryParameter("kind", kind)
          .appendQueryParameter("state", state)
          .appendQueryParameter("progress_percent", percent.toString())
          .appendQueryParameter("local_day", localDay)
          .appendQueryParameter("occurred_at", occurredAt)
          .appendQueryParameter("queue_sequence", queueSequence.toString())
          .appendQueryParameter("token", token)
          .build()
    }
  }

  data class QuickAdd(
      val id: String,
      val ownerId: String,
      val title: String,
      val scheduledAt: String?,
      val occurredAt: String,
  ) {
    fun toJson(): JSONObject = JSONObject().apply {
      put("id", id)
      put("owner_id", ownerId)
      put("title", title)
      if (scheduledAt != null) put("scheduled_at", scheduledAt)
      put("occurred_at", occurredAt)
    }

    fun toBackgroundUri(token: String?): Uri? {
      if (token.isNullOrBlank()) return null
      return Uri.Builder()
          .scheme("perfect")
          .authority("widget-quick-add")
          .appendQueryParameter("id", id)
          .appendQueryParameter("owner_id", ownerId)
          .appendQueryParameter("token", token)
          .build()
    }
  }

  fun read(prefs: SharedPreferences): Snapshot {
    val raw = prefs.getString(SNAPSHOT_KEY, null) ?: return emptySnapshot()
    return try {
      val root = JSONObject(raw)
      if (root.optInt("schema_version", 0) != 1) return emptySnapshot()
      val array = root.optJSONArray("items") ?: JSONArray()
      val items = buildList {
        for (index in 0 until array.length()) {
          val item = array.optJSONObject(index) ?: continue
          val id = item.optString("id").trim()
          if (id.isEmpty()) continue
          add(
              Item(
                  id = id,
                  kind = item.optString("kind", "one_off_task"),
                  title = item.optString("title", "Task"),
                  time = item.optString("time", "Inbox"),
                  state = item.optString("state", "pending"),
                  percent = item.optInt("progress_percent", 0).coerceIn(0, 100),
                  accent = item.optString("accent", "apricot"),
              ),
          )
        }
      }
      Snapshot(
          ownerId = root.optString("owner_id", ""),
          dateKey = root.optString("date_key", ""),
          dateLabel = root.optString("date_label", "Today"),
          updatedAtMillis = root.optLong("updated_at_millis", 0),
          items = items,
      )
    } catch (_: Exception) {
      emptySnapshot()
    }
  }

  fun cycle(context: Context, entityId: String): Action? {
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val raw = prefs.getString(SNAPSHOT_KEY, null) ?: return null
    return try {
      val root = JSONObject(raw)
      if (root.optInt("schema_version", 0) != 1) return null
      val ownerId = root.optString("owner_id", "").trim()
      val dateKey = root.optString("date_key", "").trim()
      val items = root.optJSONArray("items") ?: return null
      if (ownerId.isEmpty() || dateKey != LocalDate.now().toString()) return null
      var found: JSONObject? = null
      for (index in 0 until items.length()) {
        val item = items.optJSONObject(index) ?: continue
        if (item.optString("id") == entityId) {
          found = item
          break
        }
      }
      val item = found ?: return null
      val state = nextState(item.optString("state", "pending"))
      val percent = when (state) {
        "completed" -> 100
        "partial" -> item.optInt("progress_percent", 0)
            .takeIf { it in 1..99 }
            ?: 50
        else -> 0
      }
      item.put("state", state)
      item.put("progress_percent", percent)
      root.put("updated_at_millis", System.currentTimeMillis())
      val nextQueueSequence =
          (prefs.getLong(ACTION_SEQUENCE_KEY, 0L).coerceAtLeast(0L) + 1L)
      val action = Action(
          id = UUID.randomUUID().toString(),
          ownerId = ownerId,
          entityId = entityId,
          kind = item.optString("kind", "one_off_task"),
          state = state,
          percent = percent,
          localDay = dateKey,
          occurredAt = DateTimeFormatter.ISO_INSTANT.format(Instant.ofEpochMilli(System.currentTimeMillis())),
          queueSequence = nextQueueSequence,
      )
      val pendingActions = appendAction(prefs, action) ?: return null
      val editor = prefs.edit().putString(SNAPSHOT_KEY, root.toString())
      editor.putString(PENDING_ACTIONS_KEY, pendingActions.toString())
      editor.remove(ACKNOWLEDGED_ACTIONS_KEY)
      editor.putLong(ACTION_SEQUENCE_KEY, nextQueueSequence)
      if (!editor.commit()) return null
      action
    } catch (_: Exception) {
      null
    }
  }

  /**
   * Durably queues a quick-create request without touching Flutter's database.
   *
   * The request UUID is reused as PlannerLocalStore's mutation ID, so a
   * background retry, app foreground replay, or process restart cannot create
   * a duplicate task.
   */
  fun enqueueQuickAdd(
      context: Context,
      title: String,
      scheduledAt: String?,
  ): QuickAdd? {
    val normalizedTitle = title.trim()
    if (normalizedTitle.isEmpty() || normalizedTitle.length > 160) return null
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val ownerId = prefs.getString(OWNER_ID_KEY, null)?.trim().orEmpty()
    val token = prefs.getString(INTERACTION_TOKEN_KEY, null)?.trim().orEmpty()
    if (ownerId.isEmpty() || token.isEmpty()) return null
    val request = QuickAdd(
        id = UUID.randomUUID().toString(),
        ownerId = ownerId,
        title = normalizedTitle,
        scheduledAt = scheduledAt,
        occurredAt =
            DateTimeFormatter.ISO_INSTANT.format(
                Instant.ofEpochMilli(System.currentTimeMillis()),
            ),
    )
    val prior = try {
      JSONArray(prefs.getString(PENDING_QUICK_ADDS_KEY, "[]") ?: "[]")
    } catch (_: Exception) {
      JSONArray()
    }
    val acknowledged = try {
      val array = JSONArray(
          prefs.getString(ACKNOWLEDGED_QUICK_ADDS_KEY, "[]") ?: "[]",
      )
      buildSet {
        for (index in 0 until array.length()) {
          val id = array.optString(index).trim()
          if (id.isNotEmpty()) add(id)
        }
      }
    } catch (_: Exception) {
      emptySet()
    }
    val compacted = JSONArray()
    var remaining = 0
    for (index in 0 until prior.length()) {
      val queued = prior.optJSONObject(index) ?: continue
      if (queued.optString("id") in acknowledged) continue
      if (remaining >= MAX_QUICK_ADDS) return null
      compacted.put(queued)
      remaining += 1
    }
    if (remaining >= MAX_QUICK_ADDS) return null
    compacted.put(request.toJson())
    val committed = prefs.edit()
        .putString(PENDING_QUICK_ADDS_KEY, compacted.toString())
        .remove(ACKNOWLEDGED_QUICK_ADDS_KEY)
        .commit()
    return if (committed) request else null
  }

  private fun appendAction(prefs: SharedPreferences, action: Action): JSONArray? {
    val prior = try {
      JSONArray(prefs.getString(PENDING_ACTIONS_KEY, "[]") ?: "[]")
    } catch (_: Exception) {
      JSONArray()
    }
    val acknowledged = try {
      val array = JSONArray(
          prefs.getString(ACKNOWLEDGED_ACTIONS_KEY, "[]") ?: "[]",
      )
      buildSet {
        for (index in 0 until array.length()) {
          val id = array.optString(index).trim()
          if (id.isNotEmpty()) add(id)
        }
      }
    } catch (_: Exception) {
      emptySet()
    }
    val compacted = LinkedHashMap<String, JSONObject>()
    for (index in 0 until prior.length()) {
      val queued = prior.optJSONObject(index) ?: continue
      if (queued.optString("id") in acknowledged) continue
      val key = actionKey(queued)
      // Moving a replaced key to the tail preserves the latest native replay
      // sequence while keeping only its absolute final state.
      compacted.remove(key)
      compacted[key] = queued
    }
    val next = action.toJson()
    val nextKey = actionKey(next)
    compacted.remove(nextKey)
    compacted[nextKey] = next
    if (compacted.size > MAX_ACTIONS) {
      prefs.edit().putLong(
          QUEUE_OVERFLOW_COUNT_KEY,
          prefs.getLong(QUEUE_OVERFLOW_COUNT_KEY, 0L).coerceAtLeast(0L) + 1L,
      ).commit()
      return null
    }
    val result = JSONArray()
    compacted.values.forEach(result::put)
    return result
  }

  private fun actionKey(action: JSONObject): String {
    val ownerId = action.optString("owner_id").trim()
    val entityId = action.optString("entity_id").trim()
    val localDay = action.optString("local_day").trim()
    if (ownerId.isEmpty() || entityId.isEmpty() || localDay.isEmpty()) {
      return "legacy:${action.optString("id")}"
    }
    return "$ownerId\u0000$entityId\u0000$localDay"
  }

  private fun nextState(current: String): String = when (current) {
    "pending" -> "completed"
    "completed" -> "missed"
    "missed" -> "partial"
    else -> "pending"
  }

  private fun emptySnapshot(): Snapshot = Snapshot(
      ownerId = "",
      dateKey = "",
      dateLabel = "Today",
      updatedAtMillis = 0,
      items = emptyList(),
  )
}
