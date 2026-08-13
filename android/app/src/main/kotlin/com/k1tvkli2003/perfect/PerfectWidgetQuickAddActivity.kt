package com.k1tvkli2003.perfect

import android.app.Activity
import android.app.PendingIntent
import android.app.TimePickerDialog
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.os.Bundle
import android.R.attr.state_enabled
import android.R.attr.state_focused
import android.R.attr.state_pressed
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.widget.doAfterTextChanged
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

/**
 * Compact native capture surface launched directly from the home widget.
 *
 * This activity never opens Drift and never carries owner credentials in its
 * launch Intent. It writes one authenticated, idempotent replay request to the
 * private home_widget preferences, then asks Dart's registered background
 * callback to execute the normal local-first planner mutation.
 */
class PerfectWidgetQuickAddActivity : Activity() {
  private lateinit var titleInput: EditText
  private lateinit var submitButton: Button
  private lateinit var timeButton: Button
  private lateinit var clearTimeButton: Button
  private lateinit var errorView: TextView
  private var scheduledAt: String? = null
  private var isSubmitting = false

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setFinishOnTouchOutside(true)
    setContentView(R.layout.perfect_widget_quick_add)

    val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    applyAppearance(PerfectNativeAppearance.resolve(this, prefs))

    titleInput = findViewById(R.id.quick_add_title)
    submitButton = findViewById(R.id.quick_add_submit)
    timeButton = findViewById(R.id.quick_add_time)
    clearTimeButton = findViewById(R.id.quick_add_clear_time)
    errorView = findViewById(R.id.quick_add_error)

    val hasSession =
        !prefs.getString(PerfectTodayWidgetStore.OWNER_ID_KEY, null).isNullOrBlank() &&
            !prefs.getString(
                PerfectTodayWidgetStore.INTERACTION_TOKEN_KEY,
                null,
            ).isNullOrBlank()
    if (!hasSession) {
      findViewById<LinearLayout>(R.id.quick_add_form).visibility = View.GONE
      findViewById<LinearLayout>(R.id.quick_add_signed_out).visibility = View.VISIBLE
      findViewById<Button>(R.id.quick_add_open_app).setOnClickListener {
        startActivity(
            Intent(this, MainActivity::class.java)
                .setAction(Intent.ACTION_VIEW)
                .setData(android.net.Uri.parse("perfect://planner/today")),
        )
        finish()
      }
      return
    }

    titleInput.doAfterTextChanged {
      submitButton.isEnabled = !isSubmitting && !it.isNullOrBlank()
      if (errorView.visibility == View.VISIBLE) errorView.visibility = View.GONE
    }
    titleInput.setOnEditorActionListener { _, _, _ ->
      if (submitButton.isEnabled) submit()
      true
    }
    timeButton.setOnClickListener { chooseTime() }
    clearTimeButton.setOnClickListener { clearTime() }
    findViewById<Button>(R.id.quick_add_cancel).setOnClickListener { finish() }
    submitButton.setOnClickListener { submit() }

    titleInput.requestFocus()
    titleInput.post {
      (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
          .showSoftInput(titleInput, InputMethodManager.SHOW_IMPLICIT)
    }
  }

  private fun applyAppearance(appearance: PerfectNativeAppearance) {
    findViewById<View>(R.id.quick_add_root).background = rounded(
        colour = appearance.canvas,
        stroke = appearance.outline,
        strokeWidth = if (appearance.highContrast) 2 else 1,
        radius = 28f,
    )
    findViewById<android.widget.ImageView>(R.id.quick_add_mark)
        .setImageResource(appearance.markResource)
    findViewById<TextView>(R.id.quick_add_heading).setTextColor(appearance.ink)
    findViewById<TextView>(R.id.quick_add_subtitle).setTextColor(appearance.muted)
    findViewById<TextView>(R.id.quick_add_signed_out_message).setTextColor(appearance.muted)

    val input = findViewById<EditText>(R.id.quick_add_title)
    input.setTextColor(appearance.ink)
    input.setHintTextColor(appearance.muted)
    input.background = stateful(
        focused = rounded(
            colour = appearance.surface,
            stroke = appearance.focus,
            strokeWidth = 2,
            radius = 18f,
        ),
        pressed = rounded(
            colour = appearance.surfaceHigh,
            stroke = appearance.focus,
            strokeWidth = if (appearance.highContrast) 2 else 1,
            radius = 18f,
        ),
        normal = rounded(
            colour = appearance.surface,
            stroke = appearance.outline,
            strokeWidth = if (appearance.highContrast) 2 else 1,
            radius = 18f,
        ),
    )

    val secondary = findViewById<Button>(R.id.quick_add_time)
    secondary.setTextColor(appearance.ink)
    secondary.background = stateful(
        pressed = rounded(
            colour = appearance.surfaceHigh,
            stroke = appearance.focus,
            strokeWidth = if (appearance.highContrast) 2 else 1,
            radius = 16f,
        ),
        normal = rounded(
            colour = appearance.surface,
            stroke = appearance.outline,
            strokeWidth = if (appearance.highContrast) 2 else 1,
            radius = 16f,
        ),
    )
    for (id in intArrayOf(R.id.quick_add_clear_time, R.id.quick_add_cancel)) {
      findViewById<Button>(id).setTextColor(appearance.muted)
    }
    findViewById<TextView>(R.id.quick_add_error).setTextColor(appearance.danger)

    val primaryText = ColorStateList(
        arrayOf(intArrayOf(-state_enabled), intArrayOf()),
        intArrayOf(appearance.muted, appearance.onPrimary),
    )
    for (id in intArrayOf(R.id.quick_add_submit, R.id.quick_add_open_app)) {
      val button = findViewById<Button>(id)
      button.setTextColor(primaryText)
      button.background = primaryButton(appearance)
    }
  }

  private fun primaryButton(appearance: PerfectNativeAppearance): StateListDrawable =
      StateListDrawable().apply {
        addState(
            intArrayOf(-state_enabled),
            rounded(
                colour = appearance.surfaceHigh,
                stroke = appearance.outline,
                strokeWidth = if (appearance.highContrast) 2 else 0,
                radius = 18f,
            ),
        )
        addState(
            intArrayOf(state_pressed),
            rounded(
                colour = appearance.focus,
                stroke = appearance.ink,
                strokeWidth = if (appearance.highContrast) 2 else 0,
                radius = 18f,
            ),
        )
        addState(
            intArrayOf(),
            rounded(
                colour = appearance.primary,
                stroke = appearance.outline,
                strokeWidth = if (appearance.highContrast) 2 else 0,
                radius = 18f,
            ),
        )
      }

  private fun stateful(
      normal: GradientDrawable,
      pressed: GradientDrawable,
      focused: GradientDrawable? = null,
  ): StateListDrawable = StateListDrawable().apply {
    if (focused != null) addState(intArrayOf(state_focused), focused)
    addState(intArrayOf(state_pressed), pressed)
    addState(intArrayOf(), normal)
  }

  private fun rounded(
      colour: Int,
      stroke: Int,
      strokeWidth: Int,
      radius: Float,
  ): GradientDrawable = GradientDrawable().apply {
    shape = GradientDrawable.RECTANGLE
    setColor(colour)
    cornerRadius = radius * resources.displayMetrics.density
    if (strokeWidth > 0) {
      setStroke((strokeWidth * resources.displayMetrics.density).toInt(), stroke)
    }
  }

  private fun chooseTime() {
    val now = LocalTime.now()
    TimePickerDialog(
        this,
        { _, hour, minute ->
          val local = ZonedDateTime.of(
              LocalDate.now(),
              LocalTime.of(hour, minute),
              ZoneId.systemDefault(),
          )
          scheduledAt = DateTimeFormatter.ISO_INSTANT.format(local.toInstant())
          timeButton.text = local.format(DateTimeFormatter.ofPattern("h:mm a"))
          timeButton.contentDescription = "Task time ${timeButton.text}. Tap to change."
          clearTimeButton.visibility = View.VISIBLE
        },
        now.hour,
        now.minute,
        false,
    ).show()
  }

  private fun clearTime() {
    scheduledAt = null
    timeButton.setText(R.string.widget_quick_add_time)
    timeButton.contentDescription = "Choose an optional time for this task"
    clearTimeButton.visibility = View.GONE
  }

  private fun submit() {
    if (isSubmitting) return
    val title = titleInput.text?.toString()?.trim().orEmpty()
    if (title.isEmpty() || title.length > 160) {
      showError("Enter a task title between 1 and 160 characters.")
      return
    }
    isSubmitting = true
    submitButton.isEnabled = false
    titleInput.isEnabled = false
    timeButton.isEnabled = false
    clearTimeButton.isEnabled = false

    val request = PerfectTodayWidgetStore.enqueueQuickAdd(this, title, scheduledAt)
    if (request == null) {
      isSubmitting = false
      titleInput.isEnabled = true
      timeButton.isEnabled = true
      clearTimeButton.isEnabled = true
      submitButton.isEnabled = true
      showError("Couldn't queue this task. Open Perfect! and try again.")
      return
    }

    val token =
        getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .getString(PerfectTodayWidgetStore.INTERACTION_TOKEN_KEY, null)
    val uri = request.toBackgroundUri(token)
    if (uri != null) {
      try {
        HomeWidgetBackgroundIntent.getBroadcast(this, uri).send()
      } catch (_: PendingIntent.CanceledException) {
        // The durable native request is replayed when Perfect! next opens.
      }
    }
    PerfectTodayWidgetProvider.refresh(this)
    Toast.makeText(this, "Task added to your orbit", Toast.LENGTH_SHORT).show()
    finish()
  }

  private fun showError(message: String) {
    errorView.text = message
    errorView.visibility = View.VISIBLE
    errorView.announceForAccessibility(message)
  }
}
