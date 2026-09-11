package com.calebpierre.copypasta

import android.content.Context
import android.inputmethodservice.InputMethodService
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.InputConnection
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONArray

/**
 * Minimal accessory keyboard: shows saved clip chips plus quick text-style
 * buttons (bold/italic/etc via Unicode look-alikes) above the system
 * keyboard's own layout. Reads from the same SharedPreferences file the
 * Flutter app writes to (see SharedClipBridge) so both stay in sync
 * without a network round trip.
 */
class CopyPastaInputMethodService : InputMethodService() {

    companion object {
        private const val PREFS_NAME = "copypasta_shared"
        private const val KEY_CLIPS = "clips_json"
    }

    override fun onCreateInputView(): View {
        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(12, 12, 12, 12)

        root.addView(buildStyleRow())
        root.addView(buildClipRow())
        return root
    }

    private fun buildStyleRow(): View {
        val scroller = HorizontalScrollView(this)
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL

        val styles = listOf(
            "Bold" to FancyStyle.BOLD,
            "Italic" to FancyStyle.ITALIC,
            "Script" to FancyStyle.SCRIPT,
            "Mono" to FancyStyle.MONOSPACE,
            "SMALL" to FancyStyle.SMALL_CAPS,
        )
        for ((label, style) in styles) {
            val btn = TextView(this)
            btn.text = label
            btn.setPadding(24, 16, 24, 16)
            btn.setOnClickListener { applyStyleToSelection(style) }
            row.addView(btn)
        }
        scroller.addView(row)
        return scroller
    }

    private fun buildClipRow(): View {
        val scroller = HorizontalScrollView(this)
        val row = LinearLayout(this)
        row.orientation = LinearLayout.HORIZONTAL

        for (clip in readClips().take(20)) {
            val chip = TextView(this)
            chip.text = if (clip.length > 24) clip.take(24) + "…" else clip
            chip.setPadding(20, 16, 20, 16)
            chip.setOnClickListener { commitText(clip) }
            row.addView(chip)
        }
        scroller.addView(row)
        return scroller
    }

    private fun readClips(): List<String> {
        val prefs = createDeviceProtectedStorageContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_CLIPS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { arr.getString(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun applyStyleToSelection(style: FancyStyle) {
        val ic: InputConnection = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)?.toString()
        if (selected.isNullOrEmpty()) return
        ic.commitText(FancyTextStyler.apply(selected, style), 1)
    }
}

enum class FancyStyle { BOLD, ITALIC, SCRIPT, MONOSPACE, SMALL_CAPS }

/** Kotlin port of the Dart Unicode styler so the extension needs no Flutter engine. */
object FancyTextStyler {
    private const val UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private const val LOWER = "abcdefghijklmnopqrstuvwxyz"

    private val smallCaps = mapOf(
        'a' to 'ᴀ', 'b' to 'ʙ', 'c' to 'ᴄ', 'd' to 'ᴅ', 'e' to 'ᴇ', 'f' to 'ꜰ', 'g' to 'ɢ',
        'h' to 'ʜ', 'i' to 'ɪ', 'j' to 'ᴊ', 'k' to 'ᴋ', 'l' to 'ʟ', 'm' to 'ᴍ', 'n' to 'ɴ',
        'o' to 'ᴏ', 'p' to 'ᴘ', 'q' to 'ǫ', 'r' to 'ʀ', 's' to 'ꜱ', 't' to 'ᴛ', 'u' to 'ᴜ',
        'v' to 'ᴠ', 'w' to 'ᴡ', 'x' to 'x', 'y' to 'ʏ', 'z' to 'ᴢ',
    )

    fun apply(input: String, style: FancyStyle): String = when (style) {
        FancyStyle.BOLD -> mapBase(input, 0x1D400, 0x1D41A)
        FancyStyle.ITALIC -> mapBase(input, 0x1D434, 0x1D44E)
        FancyStyle.SCRIPT -> mapBase(input, 0x1D49C, 0x1D4B6)
        FancyStyle.MONOSPACE -> mapBase(input, 0x1D670, 0x1D68A)
        FancyStyle.SMALL_CAPS -> input.map { smallCaps[it.lowercaseChar()] ?: it }.joinToString("")
    }

    private fun mapBase(input: String, upperBase: Int, lowerBase: Int): String {
        val sb = StringBuilder()
        for (c in input) {
            val u = UPPER.indexOf(c)
            val l = LOWER.indexOf(c)
            when {
                u != -1 -> sb.appendCodePoint(upperBase + u)
                l != -1 -> sb.appendCodePoint(lowerBase + l)
                else -> sb.append(c)
            }
        }
        return sb.toString()
    }
}
