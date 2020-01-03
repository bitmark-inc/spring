/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.reactiondetail

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.modelview.ReactionModelView
import com.bitmark.fbm.util.modelview.getDrawRes
import kotlinx.android.synthetic.main.item_reaction.view.*


class ReactionRecyclerViewAdapter(private val period: Period) :
    RecyclerView.Adapter<ReactionRecyclerViewAdapter.ViewHolder>() {

    private val reactions = mutableListOf<ReactionModelView>()

    fun add(reactions: List<ReactionModelView>) {
        val pos = this.reactions.size
        this.reactions.addAll(reactions)
        notifyItemRangeInserted(pos, reactions.size)
    }

    fun isEmpty() = itemCount == 0

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder = ViewHolder(
        LayoutInflater.from(parent.context).inflate(
            R.layout.item_reaction,
            parent,
            false
        ), period
    )

    override fun getItemCount(): Int = reactions.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(reactions[position])
    }

    class ViewHolder(view: View, private val period: Period) : RecyclerView.ViewHolder(view) {

        fun bind(reaction: ReactionModelView) {
            with(itemView) {
                val context = itemView.context!!
                val date = DateTimeUtil.millisToString(
                    reaction.timestamp, if (period == Period.DECADE) {
                        DateTimeUtil.DATE_FORMAT_2
                    } else {
                        DateTimeUtil.DATE_FORMAT_3
                    }, DateTimeUtil.defaultTimeZone()
                )
                val time =
                    DateTimeUtil.millisToString(
                        reaction.timestamp,
                        DateTimeUtil.TIME_FORMAT_1,
                        DateTimeUtil.defaultTimeZone()
                    )
                val dateTime =
                    StringBuilder(context.getString(R.string.date_format_1).format(date, time))
                tvTime.text = dateTime

                tvContent.text = reaction.title
                ivType.setImageResource(reaction.getDrawRes())
            }
        }
    }
}