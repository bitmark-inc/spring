/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usagedetail

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.modelview.PostModelView
import com.bumptech.glide.Glide
import kotlinx.android.synthetic.main.item_link.view.*
import kotlinx.android.synthetic.main.item_photo.view.*
import kotlinx.android.synthetic.main.item_story.view.*
import kotlinx.android.synthetic.main.item_update.view.*
import kotlinx.android.synthetic.main.item_video.view.*


class UsageDetailRecyclerViewAdapter(private val period: Period) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val UPDATE = 0x01
        private const val PHOTO = 0x02
        private const val VIDEO = 0x03
        private const val STORY = 0x04
        private const val LINK = 0x05
    }

    private val items = mutableListOf<PostModelView>()

    fun set(items: List<PostModelView>) {
        this.items.clear()
        this.items.addAll(items)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(
            when (viewType) {
                UPDATE -> R.layout.item_update
                PHOTO  -> R.layout.item_photo
                VIDEO  -> R.layout.item_video
                STORY  -> R.layout.item_story
                LINK   -> R.layout.item_link
                else   -> error("invalid view type")
            }, parent, false
        )
        return when (viewType) {
            UPDATE -> UpdateVH(view, period)
            PHOTO  -> PhotoVH(view, period)
            VIDEO  -> VideoVH(view, period)
            STORY  -> StoryVH(view, period)
            LINK   -> LinkVH(view, period)
            else   -> error("invalid view type")
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val item = items[position]
        when (getItemViewType(position)) {
            UPDATE -> (holder as UpdateVH).bind(item)
            PHOTO  -> (holder as PhotoVH).bind(item)
            VIDEO  -> (holder as VideoVH).bind(item)
            STORY  -> (holder as StoryVH).bind(item)
            LINK   -> (holder as LinkVH).bind(item)
        }
    }

    override fun getItemViewType(position: Int): Int {
        return when (items[position].type) {
            PostType.UPDATE -> UPDATE
            PostType.PHOTO  -> PHOTO
            PostType.VIDEO  -> VIDEO
            PostType.STORY  -> STORY
            PostType.LINK   -> LINK
            else            -> error("unsupported type")
        }
    }

    open class VH(view: View, private val period: Period) : RecyclerView.ViewHolder(view) {
        protected fun getInfo(item: PostModelView): String {
            val date = DateTimeUtil.millisToString(
                item.timestamp, if (period == Period.DECADE) {
                    DateTimeUtil.DATE_FORMAT_2
                } else {
                    DateTimeUtil.DATE_FORMAT_3
                }
            )
            val time = DateTimeUtil.millisToString(item.timestamp, DateTimeUtil.TIME_FORMAT_1)
            val info = StringBuilder("$date at $time")
            val tags = item.tags
            if (tags.isNotEmpty()) {
                if (tags.size == 1) {
                    info.append(" with ${tags[0]}")
                } else {
                    info.append(" with ${tags[0]} and ${tags.size - 1} others")
                }
            }
            if (item.location != null) {
                info.append(" at ${item.location}")
            }
            return info.toString()
        }
    }

    class UpdateVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfo.text = getInfo(item)
                tvContent.text = item.content
            }
        }
    }

    class PhotoVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoPhoto.text = getInfo(item)
                tvCaptionPhoto.text = item.content
                Glide.with(context).load(item.url).into(ivPhoto)
            }
        }
    }

    class VideoVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoVideo.text = getInfo(item)
                tvCaptionVideo.text = item.content
                Glide.with(context).load(item.thumbnail).into(ivVideoPreview)
            }
        }
    }

    class StoryVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoStory.text = getInfo(item)
                tvCaptionStory.text = item.title
                Glide.with(context).load(item.url).into(ivStory)
            }
        }
    }

    class LinkVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvLinkInfo.text = getInfo(item)
                tvTitle.text = item.title
                tvLink.text = item.url
            }
        }
    }
}