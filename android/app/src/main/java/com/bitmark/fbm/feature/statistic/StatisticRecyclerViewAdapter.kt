/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.modelview.SectionModelView
import com.bitmark.fbm.util.view.statistic.GroupView
import com.bitmark.fbm.util.view.statistic.SectionView
import kotlinx.android.synthetic.main.item_trends.view.*
import kotlin.math.abs


class StatisticRecyclerViewAdapter(private val context: Context) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val HEADER = 0x01

        private const val BODY = 0x02

    }

    private val items = mutableListOf<Item>()

    private var chartClickListener: GroupView.ChartClickListener? = null

    fun setChartClickListener(listener: GroupView.ChartClickListener) {
        this.chartClickListener = listener
    }

    fun set(sections: List<SectionModelView>) {
        items.clear()
        val headerItems = getHeaderItems(context, sections)
        items.add(Item(HEADER, headerItems, null))
        items.addAll(sections.map { s -> Item(BODY, null, s) })
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return if (viewType == HEADER) {
            val view = LinearLayout(context)
            view.orientation = LinearLayout.HORIZONTAL
            val paddingHorizontally = context.getDimensionPixelSize(R.dimen.dp_18)
            val paddingVertically = context.getDimensionPixelSize(R.dimen.dp_32)
            view.setPadding(
                paddingHorizontally,
                paddingVertically,
                paddingHorizontally,
                paddingVertically
            )
            view.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            HeaderVH(view)
        } else {
            val sectionView = SectionView(parent.context)
            if (chartClickListener != null) {
                sectionView.setChartClickListener(chartClickListener!!)
            }
            BodyVH(sectionView)
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val viewType = getItemViewType(position)
        if (viewType == HEADER) {
            (holder as? HeaderVH)?.bind(items[position])
        } else if (viewType == BODY) {
            (holder as? BodyVH)?.bind(items[position])
        }
    }

    override fun getItemViewType(position: Int): Int {
        return items[position].type
    }

    private fun getHeaderItems(
        context: Context,
        sections: List<SectionModelView>
    ): List<HeaderItem> {
        if (sections.isEmpty()) return listOf()
        val items = mutableListOf<HeaderItem>()
        for (section in sections) {
            items.add(
                HeaderItem(
                    context.getString(
                        when (section.name) {
                            SectionName.POST        -> R.string.posts
                            SectionName.REACTION    -> R.string.reactions
                            SectionName.MESSAGE     -> R.string.messages
                            SectionName.AD_INTEREST -> R.string.ad_interests
                            SectionName.ADVERTISER  -> R.string.advertisers
                            SectionName.LOCATION    -> R.string.locations
                        }
                    ), section.diffFromPrev
                )
            )
        }
        return items
    }

    class BodyVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            (itemView as SectionView).bind(item.section!!)
        }
    }

    class HeaderVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            val headerItems = item.headerItems!!
            val root = itemView as LinearLayout
            root.removeAllViews()
            if (headerItems.isEmpty()) return
            val weight = 1.0f / headerItems.size
            headerItems.forEach { i ->
                val view = LayoutInflater.from(root.context).inflate(R.layout.item_trends, null)
                val params = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT)
                params.weight = weight
                view.layoutParams = params
                root.addView(view)

                with(view) {
                    tvSecName.text = i.sectionName
                    tvSecTrend.text = "%d%%".format(abs(i.diffFromPrev))
                    ivSecTrend.setImageResource(getImageRes(i))
                }
            }
        }

        private fun getImageRes(headerItem: HeaderItem) = when {
            headerItem.diffFromPrev > 0 -> R.drawable.ic_circle_arrow_up
            headerItem.diffFromPrev < 0 -> R.drawable.ic_circle_arrow_down
            else                        -> R.drawable.ic_trending_neutral
        }
    }

    data class Item(
        val type: Int,
        val headerItems: List<HeaderItem>?,
        val section: SectionModelView?
    )

    data class HeaderItem(val sectionName: String, val diffFromPrev: Int)
}