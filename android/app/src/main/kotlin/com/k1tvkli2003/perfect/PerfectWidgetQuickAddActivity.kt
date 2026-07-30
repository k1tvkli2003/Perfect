package com.k1tvkli2003.perfect

import android.app.Activity
import android.app.PendingIntent
import android.app.TimePickerDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
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

    titleInput = findViewById(R.id.quick_add_title)
    submitButton = findViewById(R.id.quick_add_submit)
    timeButton = findViewById(R.id.quick_add_time)
    clearTimeButton = findViewById(R.id.quick_add_clear_time)
    errorView = findViewById(R.id.quick_add_error)

    val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
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
