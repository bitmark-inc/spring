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
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.modelview.SectionModelView
import com.bitmark.fbm.util.view.statistic.GroupView
import com.bitmark.fbm.util.view.statistic.SectionView
import kotlinx.android.synthetic.main.item_income.view.*
import kotlinx.android.synthetic.main.item_sentiment.view.*
import kotlinx.android.synthetic.main.item_trends.view.*
import kotlin.math.abs


class StatisticRecyclerViewAdapter(private val context: Context) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {

        private const val HEADER = 0x01

        private const val STATISTIC = 0x02

        private const val INCOME = 0x03

        private const val SENTIMENT = 0x04

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
        items.addAll(sections.map { s ->
            val type = when (s.name) {
                SectionName.SENTIMENT -> SENTIMENT
                SectionName.FB_INCOME -> INCOME
                else                  -> STATISTIC
            }
            Item(type, null, s)
        })
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            HEADER    -> {
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
            }

            STATISTIC -> {
                val sectionView = SectionView(parent.context)
                if (chartClickListener != null) {
                    sectionView.setChartClickListener(chartClickListener!!)
                }
                StatisticVH(sectionView)
            }

            INCOME    -> IncomeVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_income,
                    parent,
                    false
                )
            )

            SENTIMENT -> SentimentVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_sentiment,
                    parent,
                    false
                )
            )

            else      -> error("invalid view type")
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (getItemViewType(position)) {
            HEADER    -> (holder as? HeaderVH)?.bind(items[position])
            STATISTIC -> (holder as? StatisticVH)?.bind(items[position])
            INCOME    -> (holder as? IncomeVH)?.bind(items[position])
            SENTIMENT -> (holder as? SentimentVH)?.bind(items[position])
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
                            SectionName.FB_INCOME   -> R.string.income
                            SectionName.SENTIMENT   -> R.string.mood
                        }
                    ), section.diffFromPrev
                )
            )
        }
        return items
    }

    class IncomeVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            with(itemView) {
                ivIncome.text = String.format("$%.2f", item.section?.value ?: 0f)
            }
        }
    }

    class SentimentVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            val value = item.section?.value
            with(itemView) {
                ivSeekbar.setImageResource(
                    when (value) {
                        1f   -> R.drawable.ic_seek_bar_1
                        2f   -> R.drawable.ic_seek_bar_2
                        3f   -> R.drawable.ic_seek_bar_3
                        4f   -> R.drawable.ic_seek_bar_4
                        5f   -> R.drawable.ic_seek_bar_5
                        6f   -> R.drawable.ic_seek_bar_6
                        7f   -> R.drawable.ic_seek_bar_7
                        8f   -> R.drawable.ic_seek_bar_8
                        9f   -> R.drawable.ic_seek_bar_9
                        10f  -> R.drawable.ic_seek_bar_10
                        else -> R.drawable.ic_seek_bar_0
                    }
                )

                ivSentiment.setImageResource(
                    when (value) {
                        1f, 2f  -> R.drawable.ic_anger_bw
                        3f, 4f  -> R.drawable.ic_sad_bw
                        5f, 6f  -> R.drawable.ic_no_feeling_bw
                        7f, 8f  -> R.drawable.ic_smile_bw
                        9f, 10f -> R.drawable.ic_happy_bw
                        else    -> R.drawable.ic_wow_bw
                    }
                )

                if (value == null) tvNoData.visible() else tvNoData.gone()
            }
        }
    }

    class StatisticVH(view: View) : RecyclerView.ViewHolder(view) {

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
                    if (i.diffFromPrev != null) {
                        tvSecTrend.text = "%d%%".format(abs(i.diffFromPrev))
                        ivSecTrend.setImageResource(getImageRes(i.diffFromPrev))
                        tvNoValue.gone()
                        layoutVal.visible()
                    } else {
                        layoutVal.gone()
                        tvNoValue.visible()
                    }
                    tvSecName.text = i.sectionName
                }
            }
        }

        private fun getImageRes(diff: Int) = when {
            diff > 0 -> R.drawable.ic_circle_arrow_up
            diff < 0 -> R.drawable.ic_circle_arrow_down
            else     -> R.drawable.ic_trending_neutral
        }
    }

    data class Item(
        val type: Int,
        val headerItems: List<HeaderItem>?,
        val section: SectionModelView?
    )

    data class HeaderItem(val sectionName: String, val diffFromPrev: Int?)
}