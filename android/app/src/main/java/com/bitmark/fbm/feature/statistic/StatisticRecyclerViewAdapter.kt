/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.SectionName
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.modelview.SectionModelView
import com.bitmark.fbm.util.view.statistic.GroupView
import com.bitmark.fbm.util.view.statistic.SectionView
import kotlinx.android.synthetic.main.item_sentiment.view.*
import kotlin.math.roundToInt


class StatisticRecyclerViewAdapter :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {

        private const val SENTIMENT = 0x01

        private const val STATISTIC = 0x02

    }

    private val items = mutableListOf<Item>()

    private var chartClickListener: GroupView.ChartClickListener? = null

    fun setChartClickListener(listener: GroupView.ChartClickListener) {
        this.chartClickListener = listener
    }

    fun set(sections: List<SectionModelView>) {
        items.clear()
        items.addAll(sections.map { s ->
            val type = when (s.name) {
                SectionName.SENTIMENT -> SENTIMENT
                else -> STATISTIC
            }
            Item(type, s)
        })
        notifyDataSetChanged()
    }

    fun clear() {
        items.clear()
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            STATISTIC -> {
                val sectionView = SectionView(parent.context)
                if (chartClickListener != null) {
                    sectionView.setChartClickListener(chartClickListener!!)
                }
                StatisticVH(sectionView)
            }

            SENTIMENT -> SentimentVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_sentiment,
                    parent,
                    false
                )
            )

            else -> error("invalid view type")
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (getItemViewType(position)) {
            STATISTIC -> (holder as? StatisticVH)?.bind(items[position])
            SENTIMENT -> (holder as? SentimentVH)?.bind(items[position])
        }

    }

    override fun getItemViewType(position: Int): Int {
        return items[position].type
    }

    class SentimentVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            val value = item.section?.value
            with(itemView) {
                if (value != null) {
                    tvNoData.gone()
                    val rounded = value.roundToInt()
                    ivSeekbar.setImageResource(
                        when (rounded) {
                            0, 1 -> R.drawable.ic_seek_bar_1
                            2 -> R.drawable.ic_seek_bar_2
                            3 -> R.drawable.ic_seek_bar_3
                            4 -> R.drawable.ic_seek_bar_4
                            5 -> R.drawable.ic_seek_bar_5
                            6 -> R.drawable.ic_seek_bar_6
                            7 -> R.drawable.ic_seek_bar_7
                            8 -> R.drawable.ic_seek_bar_8
                            9 -> R.drawable.ic_seek_bar_9
                            10 -> R.drawable.ic_seek_bar_10
                            else -> R.drawable.ic_seek_bar_0
                        }
                    )

                    ivSentiment.setImageResource(
                        when {
                            rounded in 0..1 -> R.drawable.ic_cry_bw
                            rounded in 2..3 -> R.drawable.ic_sad_bw
                            rounded in 4..5 -> R.drawable.ic_no_feeling_bw
                            rounded in 6..7 -> R.drawable.ic_smile_bw
                            rounded >= 8 -> R.drawable.ic_happy_bw
                            else -> R.drawable.ic_wow_bw
                        }
                    )
                } else {
                    tvNoData.visible()
                    ivSentiment.setImageResource(R.drawable.ic_wow_bw)
                    ivSeekbar.setImageResource(R.drawable.ic_seek_bar_0)
                }
            }
        }
    }

    class StatisticVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: Item) {
            (itemView as SectionView).bind(item.section!!)
        }
    }

    data class Item(
        val type: Int,
        val section: SectionModelView?
    )
}