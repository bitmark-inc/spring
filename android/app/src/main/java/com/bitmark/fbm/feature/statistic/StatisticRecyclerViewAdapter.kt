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
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.SectionName
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

        private const val HEADER_ITEM_SIZE = 3
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
            HeaderVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_trends,
                    parent,
                    false
                )
            )
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
            if (headerItems.size != HEADER_ITEM_SIZE) return
            with(itemView) {
                val item1 = headerItems[0]
                val item2 = headerItems[1]
                val item3 = headerItems[2]
                tvSecName1.text = item1.sectionName
                tvSecName2.text = item2.sectionName
                tvSecName3.text = item3.sectionName
                tvSecTrend1.text = "%d%%".format(abs(item1.diffFromPrev))
                tvSecTrend2.text = "%d%%".format(abs(item2.diffFromPrev))
                tvSecTrend3.text = "%d%%".format(abs(item3.diffFromPrev))
                ivSecTrend1.setImageResource(getImageRes(item1))
                ivSecTrend2.setImageResource(getImageRes(item2))
                ivSecTrend3.setImageResource(getImageRes(item3))
            }
        }

        private fun getImageRes(headerItem: HeaderItem): Int {
            return if (headerItem.diffFromPrev >= 0) {
                R.drawable.ic_circle_arrow_up
            } else {
                R.drawable.ic_circle_arrow_down
            }
        }
    }

    data class Item(
        val type: Int,
        val headerItems: List<HeaderItem>?,
        val section: SectionModelView?
    )

    data class HeaderItem(val sectionName: String, val diffFromPrev: Int)
}