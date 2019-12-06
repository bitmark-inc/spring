package com.bitmark.fbm.util.view

import android.content.Context
import android.util.AttributeSet
import androidx.viewpager.widget.ViewPager

class NestedViewPager(context: Context, attrs: AttributeSet?) : ViewPager(context, attrs) {

    constructor(context: Context) : this(context, null)

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        var hSpecs = heightMeasureSpec
        val child = getChildAt(currentItem)
        if (child != null) {
            child.measure(
                widthMeasureSpec,
                MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
            )
            val h = child.measuredHeight
            hSpecs = MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
        }
        super.onMeasure(widthMeasureSpec, hSpecs)
    }
}
