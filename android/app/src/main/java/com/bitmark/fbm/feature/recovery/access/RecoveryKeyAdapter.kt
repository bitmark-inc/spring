/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.recovery.access

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import kotlinx.android.synthetic.main.item_recovery_key.view.*


class RecoveryKeyAdapter : RecyclerView.Adapter<RecoveryKeyAdapter.ViewHolder>() {

    private val words = mutableListOf<String>()

    fun set(words: List<String>) {
        this.words.clear()
        this.words.addAll(words)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view =
            LayoutInflater.from(parent.context).inflate(R.layout.item_recovery_key, parent, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int = words.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(words[position])
    }


    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {

        fun bind(item: String) {
            with(itemView) {
                tvWord.text = item
            }
        }
    }
}