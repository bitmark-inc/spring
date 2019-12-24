/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.locationdetail

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.modelview.LocationModelView
import com.bitmark.fbm.util.modelview.coordinateString
import kotlinx.android.synthetic.main.item_location.view.*


class LocationRecyclerViewAdapter(private val period: Period) :
    RecyclerView.Adapter<LocationRecyclerViewAdapter.ViewHolder>() {

    private val locations = mutableListOf<LocationModelView>()

    fun add(locations: List<LocationModelView>) {
        val pos = this.locations.size
        this.locations.addAll(locations)
        notifyItemRangeInserted(pos, locations.size)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder = ViewHolder(
        LayoutInflater.from(parent.context).inflate(
            R.layout.item_location,
            parent,
            false
        ), period
    )

    override fun getItemCount(): Int = locations.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(locations[position])
    }

    class ViewHolder(view: View, private val period: Period) : RecyclerView.ViewHolder(view) {

        fun bind(location: LocationModelView) {
            with(itemView) {
                val context = itemView.context!!
                val date = DateTimeUtil.millisToString(
                    location.createdAt, if (period == Period.DECADE) {
                        DateTimeUtil.DATE_FORMAT_2
                    } else {
                        DateTimeUtil.DATE_FORMAT_3
                    },
                    DateTimeUtil.defaultTimeZone()
                )
                val time =
                    DateTimeUtil.millisToString(
                        location.createdAt,
                        DateTimeUtil.TIME_FORMAT_1,
                        DateTimeUtil.defaultTimeZone()
                    )
                val dateTime =
                    StringBuilder(context.getString(R.string.date_format_1).format(date, time))
                tvInfo.text = dateTime
                tvContent.text = location.coordinateString()
            }
        }
    }
}