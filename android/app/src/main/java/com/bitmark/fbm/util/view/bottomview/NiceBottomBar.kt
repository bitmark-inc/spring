/**
Copyright (c) 2019 İbrahim Süren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
package com.bitmark.fbm.util.view.bottomview

import android.animation.ArgbEvaluator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import android.view.animation.*
import androidx.annotation.ColorRes
import androidx.core.content.res.ResourcesCompat
import androidx.core.graphics.drawable.DrawableCompat
import com.bitmark.fbm.R
import com.bitmark.fbm.util.view.bottomview.Constants.DEFAULT_INDICATOR_COLOR
import com.bitmark.fbm.util.view.bottomview.Constants.DEFAULT_TEXT_COLOR
import com.bitmark.fbm.util.view.bottomview.Constants.DEFAULT_TEXT_COLOR_ACTIVE
import com.bitmark.fbm.util.view.bottomview.Constants.WHITE_COLOR_HEX
import kotlin.math.abs

class NiceBottomBar : View {

    // Default attribute values
    private var barBackgroundColor = Color.parseColor(WHITE_COLOR_HEX)
    private var barIndicatorColor = Color.parseColor(DEFAULT_INDICATOR_COLOR)
    private var barIndicatorInterpolator = 4
    private var barIndicatorWidth = d2p(50f)
    private var barIndicatorEnabled = true
    private var barIndicatorGravity = 1
    private var itemIconSize = d2p(18f)
    private var itemIconMargin = d2p(3f)
    private var itemTextColor = Color.parseColor(DEFAULT_TEXT_COLOR)
    private var itemTextColorActive = Color.parseColor(DEFAULT_TEXT_COLOR_ACTIVE)
    private var itemTextSize = d2p(11.0f)
    private var itemBadgeColor = itemTextColorActive
    private var itemFontFamily = 0
    private var activeItem = 0

    /**
     * Dynamic variables
     */
    private var currentActiveItemColor = itemTextColor
    private var indicatorLocation = 0f

    // Represent long press time, when press time > longPressTime call the function callback.onItemLongClick
    private var longPressTime = 500
    private val titleSideMargins = d2p(12f)

    private var items = listOf<BottomBarItem>()

    var onItemSelected: (Int) -> Unit = {}
    var onItemReselected: (Int) -> Unit = {}
    var onItemLongClick: (Int) -> Unit = {}

    private val paintIndicator = Paint().apply {
        isAntiAlias = true
        style = Paint.Style.STROKE
        strokeWidth = 10f
        color = barIndicatorColor
        strokeCap = Paint.Cap.ROUND
    }

    private val paintText = Paint().apply {
        isAntiAlias = true
        style = Paint.Style.FILL
        color = itemTextColor
        textSize = itemTextSize
        textAlign = Paint.Align.CENTER
        isFakeBoldText = true
    }

    private val paintBadge = Paint().apply {
        isAntiAlias = true
        style = Paint.Style.FILL
        color = itemBadgeColor
        strokeWidth = 4f
    }

    constructor(context: Context) : super(context)
    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
        val typedArray =
            context.theme.obtainStyledAttributes(attrs, R.styleable.NiceBottomBar, 0, 0)
        barBackgroundColor =
            typedArray.getColor(R.styleable.NiceBottomBar_backgroundColor, this.barBackgroundColor)
        barIndicatorColor =
            typedArray.getColor(R.styleable.NiceBottomBar_indicatorColor, this.barIndicatorColor)
        barIndicatorWidth = typedArray.getDimension(
            R.styleable.NiceBottomBar_indicatorWidth,
            this.barIndicatorWidth
        )
        barIndicatorEnabled = typedArray.getBoolean(
            R.styleable.NiceBottomBar_indicatorEnabled,
            this.barIndicatorEnabled
        )
        itemTextColor = typedArray.getColor(R.styleable.NiceBottomBar_textColor, this.itemTextColor)
        itemTextColorActive =
            typedArray.getColor(R.styleable.NiceBottomBar_textColorActive, this.itemTextColorActive)
        itemTextSize =
            typedArray.getDimension(R.styleable.NiceBottomBar_textSize, this.itemTextSize)
        itemIconSize =
            typedArray.getDimension(R.styleable.NiceBottomBar_iconSize, this.itemIconSize)
        itemIconMargin =
            typedArray.getDimension(R.styleable.NiceBottomBar_iconMargin, this.itemIconMargin)
        activeItem = typedArray.getInt(R.styleable.NiceBottomBar_activeItem, this.activeItem)
        barIndicatorInterpolator = typedArray.getInt(
            R.styleable.NiceBottomBar_indicatorInterpolator,
            this.barIndicatorInterpolator
        )
        barIndicatorGravity =
            typedArray.getInt(R.styleable.NiceBottomBar_indicatorGravity, this.barIndicatorGravity)
        itemBadgeColor =
            typedArray.getColor(R.styleable.NiceBottomBar_badgeColor, this.itemBadgeColor)
        itemFontFamily =
            typedArray.getResourceId(R.styleable.NiceBottomBar_itemFontFamily, this.itemFontFamily)
        items = BottomBarParser(
            context,
            typedArray.getResourceId(R.styleable.NiceBottomBar_menu, 0)
        ).parse()
        typedArray.recycle()

        setBackgroundColor(barBackgroundColor)

        // Update default attribute values
        paintIndicator.color = barIndicatorColor
        paintText.color = itemTextColor
        paintText.textSize = itemTextSize
        paintBadge.color = itemBadgeColor

        if (itemFontFamily != 0)
            paintText.typeface = ResourcesCompat.getFont(context, itemFontFamily)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)

        var lastX = 0f
        val itemWidth = width / items.size

        for (item in items) {
            // Prevent text overflow by shortening the item title
            var shorted = false
            while (paintText.measureText(item.title) > (itemWidth - titleSideMargins)) {
                item.title = item.title.dropLast(1)
                shorted = true
            }

            // Add ellipsis character to item text if it is shorted
            if (shorted) {
                item.title = item.title.dropLast(1)
                item.title += "..."
            }

            item.rect = RectF(lastX, 0f, itemWidth + lastX, height.toFloat())
            lastX += itemWidth
        }

        // Set initial active item
        setActiveItem(activeItem)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val textHeight = (paintText.descent() + paintText.ascent()) / 2

        // Push the item components from the top a bit if the indicator is at the top
        val additionalTopMargin = if (barIndicatorGravity == 1) 0f else 10f

        for ((i, item) in items.withIndex()) {
            item.icon.mutate()
            item.icon.setBounds(
                item.rect.centerX().toInt() - itemIconSize.toInt() / 2,
                height / 2 - itemIconSize.toInt() - itemIconMargin.toInt() / 2 + additionalTopMargin.toInt(),
                item.rect.centerX().toInt() + itemIconSize.toInt() / 2,
                height / 2 - itemIconMargin.toInt() / 2 + additionalTopMargin.toInt()
            )

            DrawableCompat.setTint(
                item.icon,
                if (i == activeItem) currentActiveItemColor else itemTextColor
            )
            item.icon.draw(canvas)

            // Draw item title
            this.paintText.color = if (i == activeItem) currentActiveItemColor else itemTextColor
            canvas.drawText(
                item.title,
                item.rect.centerX(),
                item.rect.centerY() - textHeight + itemIconSize / 2 + (this.itemIconMargin / 2) + additionalTopMargin,
                paintText
            )

            // Draw item badge
            if (item.badgeSize > 0)
                drawBadge(canvas, item)
        }

        // Draw indicator
        if (barIndicatorEnabled) {
            canvas.drawLine(
                indicatorLocation - barIndicatorWidth / 2,
                (if (barIndicatorGravity == 1) height - 5f else 5f),
                indicatorLocation + barIndicatorWidth / 2,
                (if (barIndicatorGravity == 1) height - 5f else 5f),
                paintIndicator
            )
        }
    }

    // Handle item clicks
    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_UP && abs(event.downTime - event.eventTime) < longPressTime)
            for ((i, item) in items.withIndex())
                if (item.rect.contains(event.x, event.y))
                    if (i != this.activeItem) {
                        onItemSelected(i)
                        setActiveItem(i)
                    } else {
                        onItemReselected(i)
                    }

        if (event.action == MotionEvent.ACTION_MOVE || event.action == MotionEvent.ACTION_UP)
            if (abs(event.downTime - event.eventTime) > longPressTime)
                for ((i, item) in items.withIndex())
                    if (item.rect.contains(event.x, event.y)) {
                        onItemLongClick(i)
                    }

        return true
    }

    // Draw item badge
    private fun drawBadge(canvas: Canvas, item: BottomBarItem) {
        paintBadge.style = Paint.Style.FILL
        paintBadge.color = itemTextColorActive

        canvas.drawCircle(
            item.rect.centerX() + itemIconSize / 2 - 4,
            (height / 2).toFloat() - itemIconSize - itemIconMargin / 2 + 10,
            item.badgeSize,
            paintBadge
        )

        paintBadge.style = Paint.Style.STROKE
        paintBadge.color = barBackgroundColor

        canvas.drawCircle(
            item.rect.centerX() + itemIconSize / 2 - 4,
            (height / 2).toFloat() - itemIconSize - itemIconMargin / 2 + 10,
            item.badgeSize,
            paintBadge
        )
    }

    // Add item badge
    fun setBadge(pos: Int) {
        if (pos > 0 && pos < items.size && items[pos].badgeSize == 0f) {
            val animator = ValueAnimator.ofFloat(0f, 15f)
            animator.duration = 100
            animator.addUpdateListener { animation ->
                items[pos].badgeSize = animation.animatedValue as Float
                invalidate()
            }
            animator.start()
        }
    }

    // Remove item badge
    fun removeBadge(pos: Int) {
        if (pos > 0 && pos < items.size && items[pos].badgeSize > 0f) {
            val animator = ValueAnimator.ofFloat(items[pos].badgeSize, 0f)
            animator.duration = 100
            animator.addUpdateListener { animation ->
                items[pos].badgeSize = animation.animatedValue as Float
                invalidate()
            }
            animator.start()
        }
    }

    fun setActiveItem(pos: Int, @ColorRes color: Int? = null) {
        if (color != null) {
            setActiveColor(color)
        }
        activeItem = pos

        animateIndicator(pos)
        setItemColors()
    }

    fun setIndicatorWidth(px: Float) {
        barIndicatorWidth = px
    }

    fun setActiveColor(@ColorRes color: Int) {
        val c = context.getColor(color)
        itemTextColorActive = c
        itemBadgeColor = c
        barIndicatorColor = c
        paintIndicator.color = c
        paintText.color = c
    }

    private fun animateIndicator(pos: Int) {
        val animator = ValueAnimator.ofFloat(indicatorLocation, items[pos].rect.centerX())
        animator.interpolator = when (this.barIndicatorInterpolator) {
            0    -> AccelerateInterpolator()
            1    -> DecelerateInterpolator()
            2    -> AccelerateDecelerateInterpolator()
            3    -> AnticipateInterpolator()
            4    -> AnticipateOvershootInterpolator()
            5    -> LinearInterpolator()
            6    -> OvershootInterpolator()
            else -> AnticipateOvershootInterpolator()
        }

        animator.addUpdateListener { animation ->
            indicatorLocation = animation.animatedValue as Float
            invalidate()
        }
        animator.duration = 100

        animator.start()
    }

    // Apply transition animation to item color
    private fun setItemColors() {
        val animator =
            ValueAnimator.ofObject(ArgbEvaluator(), itemTextColor, itemTextColorActive)
        animator.addUpdateListener { currentActiveItemColor = it.animatedValue as Int }
        animator.start()
    }

    private fun d2p(dp: Float): Float {
        return resources.displayMetrics.densityDpi.toFloat() / 160.toFloat() * dp
    }


}