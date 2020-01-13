/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.insights

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.modelview.InsightModelView
import kotlinx.android.synthetic.main.item_categories.view.*
import kotlinx.android.synthetic.main.item_category.view.*
import kotlinx.android.synthetic.main.item_income.view.*


class InsightsRecyclerViewAdapter : RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val INCOME = 0x00
        private const val CATEGORY = 0x01
    }

    private val items = mutableListOf<InsightModelView>()

    private var itemClickListener: ItemClickListener? = null

    fun set(insights: List<InsightModelView>) {
        items.clear()
        items.addAll(insights)
        notifyDataSetChanged()
    }

    fun clear() {
        items.clear()
        notifyDataSetChanged()
    }

    fun isEmpty() = itemCount == 0

    fun setItemClickListener(listener: ItemClickListener?) {
        this.itemClickListener = listener
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            INCOME -> IncomeVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_income,
                    parent,
                    false
                ), itemClickListener
            )
            CATEGORY -> CategoryVH(
                LayoutInflater.from(parent.context).inflate(
                    R.layout.item_categories,
                    parent,
                    false
                )
            )
            else -> error("unsupported view type")
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (holder) {
            is IncomeVH -> holder.bind(items[position])
            is CategoryVH -> holder.bind(items[position])
            else -> error("unsupported holder")
        }
    }

    override fun getItemViewType(position: Int): Int {
        val item = items[position]
        return when {
            item.income != null -> INCOME
            item.categories != null -> CATEGORY
            else -> error("unsupported view type")
        }
    }

    class IncomeVH(view: View, listener: ItemClickListener?) : RecyclerView.ViewHolder(view) {

        init {
            with(itemView) {
                ivInfo.setOnClickListener { listener?.onIncomeInfoClicked() }
            }
        }

        fun bind(item: InsightModelView) {
            with(itemView) {
                if (item.income == null || item.income <= 0f) {
                    tvIncome.text = "--"
                    tvMsg.text = context.getString(R.string.sorry_no_data)
                } else {
                    tvIncome.text = String.format("$%.2f", item.income)
                    tvMsg.text = context.getString(R.string.income_fb_made_from_you_format)
                        .format(
                            DateTimeUtil.millisToString(
                                item.incomeFrom!! * 1000,
                                DateTimeUtil.DATE_FORMAT_11,
                                DateTimeUtil.defaultTimeZone()
                            )
                        )
                }
            }
        }
    }

    class CategoryVH(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: InsightModelView) {
            if (item.categories == null) error("categories is null")
            with(itemView) {
                val root = itemView as LinearLayout
                root.removeViews(3, root.childCount - 3)

                if (item.categories.isEmpty()) {
                    tvNoData.visible()
                } else {
                    tvNoData.gone()
                    item.categories.forEachIndexed { i, category ->
                        val categoryView =
                            LayoutInflater.from(context).inflate(R.layout.item_category, null)
                        categoryView.tvCategory.text = category
                        val params = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.MATCH_PARENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        )
                        val marginTop =
                            context.getDimensionPixelSize(if (i == 0) R.dimen.dp_24 else R.dimen.dp_16)
                        params.setMargins(0, marginTop, 0, 0)
                        root.addView(categoryView, params)
                    }
                }

            }
        }
    }

    interface ItemClickListener {

        fun onIncomeInfoClicked()
    }
}