/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.util.view.statistic

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.widget.LinearLayout
import androidx.core.view.children
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.modelview.GroupModelView
import com.bitmark.fbm.util.modelview.SectionModelView
import kotlinx.android.synthetic.main.layout_section.view.*
import kotlinx.android.synthetic.main.layout_section_header.view.*


class SectionView(context: Context, attrs: AttributeSet?, defStyleAttr: Int) :
    LinearLayout(context, attrs, defStyleAttr) {

    companion object {
        private const val DEFAULT_CHILD_COUNT = 1
    }

    constructor(context: Context) : this(context, null, 0)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    private var chartClickListener: GroupView.ChartClickListener? = null

    init {
        inflate(context, R.layout.layout_section, this)

        orientation = VERTICAL
        val paddingHorizontal = context.getDimensionPixelSize(R.dimen.dp_18)
        val paddingVertical = context.getDimensionPixelSize(R.dimen.dp_30)
        setPadding(paddingHorizontal, paddingVertical, paddingHorizontal, paddingVertical)
        val params = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        layoutParams = params
    }

    fun setChartClickListener(listener: GroupView.ChartClickListener) {
        this.chartClickListener = listener
    }

    fun bind(section: SectionModelView) {
        when (section.name) {
            SectionName.POST        -> {
                tvOverview.text = context.getString(R.string.posts_format).format(section.quantity)
                tvOverviewSuffix.text = context.getString(R.string.you_made).toLowerCase()
            }
            SectionName.REACTION    -> {
                tvOverview.text =
                    context.getString(R.string.reactions_format).format(section.quantity)
                tvOverviewSuffix.text = context.getString(R.string.you_gave).toLowerCase()
            }
            SectionName.MESSAGE     -> {
                tvOverview.text =
                    context.getString(R.string.messages_format).format(section.quantity)
                tvOverviewSuffix.text =
                    context.getString(R.string.you_sent_or_received).toLowerCase()
            }
            SectionName.AD_INTEREST -> {
                tvOverview.text =
                    context.getString(R.string.ad_interests_format).format(section.quantity)
                tvOverviewSuffix.text = context.getString(R.string.tracked_by_fb).toLowerCase()
            }
            SectionName.ADVERTISER  -> {
                tvOverview.text =
                    context.getString(R.string.advertiser_format).format(section.quantity)
                tvOverviewSuffix.text =
                    context.getString(R.string.collected_data_about_you).toLowerCase()
            }
            SectionName.LOCATION    -> {
                tvOverview.text =
                    context.getString(R.string.locations_format).format(section.quantity)
                tvOverviewSuffix.text = context.getString(R.string.tracked_by_fb).toLowerCase()
            }
        }

        val groups = section.groups
        val isNoData = section.isNoData()

        tvEmpty.visibility = if (isNoData) View.VISIBLE else View.GONE
        removeGroups()
        if (isNoData) return

        addGroups(groups)
        bindGroupsData(groups)
    }

    private fun removeGroups() {
        val count = children.filter { v -> v is GroupView }.count()
        if (count == 0) return
        removeViews(DEFAULT_CHILD_COUNT, count)
    }

    private fun addGroups(groups: List<GroupModelView>) {
        for (index in groups.indices) {
            val groupView = GroupView(context)
            val params = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
            params.setMargins(0, context.getDimensionPixelSize(R.dimen.dp_25), 0, 0)
            groupView.layoutParams = params
            if (chartClickListener != null) {
                groupView.setChartClickListener(chartClickListener!!)
            }
            addView(groupView, index + DEFAULT_CHILD_COUNT)
        }
    }

    private fun bindGroupsData(groups: List<GroupModelView>) {
        for (index in DEFAULT_CHILD_COUNT until childCount) {
            val view = getChildAt(index) as? GroupView
            view?.bind(groups[index - 1])
        }
    }
}