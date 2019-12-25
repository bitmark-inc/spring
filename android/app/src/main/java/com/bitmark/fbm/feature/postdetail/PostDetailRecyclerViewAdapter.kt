/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.postdetail

import android.text.SpannableString
import android.text.Spanned
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.load
import com.bitmark.fbm.util.ext.openBrowser
import com.bitmark.fbm.util.ext.removeQuote
import com.bitmark.fbm.util.ext.toHtmlSpan
import com.bitmark.fbm.util.modelview.PostModelView
import com.bitmark.fbm.util.view.NoUnderlineSpan
import kotlinx.android.synthetic.main.item_link.view.*
import kotlinx.android.synthetic.main.item_photo.view.*
import kotlinx.android.synthetic.main.item_story.view.*
import kotlinx.android.synthetic.main.item_update.view.*


class PostDetailRecyclerViewAdapter(private val period: Period) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val UPDATE = 0x01
        private const val MEDIA = 0x02
        private const val STORY = 0x03
        private const val LINK = 0x04
    }

    private val items = mutableListOf<PostModelView>()

    fun add(items: List<PostModelView>) {
        val pos = this.items.size
        this.items.addAll(items)
        notifyItemRangeInserted(pos, items.size)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(
            when (viewType) {
                UPDATE -> R.layout.item_update
                MEDIA  -> R.layout.item_photo
                STORY  -> R.layout.item_story
                LINK   -> R.layout.item_link
                else   -> error("invalid view type")
            }, parent, false
        )
        return when (viewType) {
            UPDATE -> UpdateVH(view, period)
            MEDIA  -> MediaVH(view, period)
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
            MEDIA  -> (holder as MediaVH).bind(item)
            STORY  -> (holder as StoryVH).bind(item)
            LINK   -> (holder as LinkVH).bind(item)
        }
    }

    override fun getItemViewType(position: Int): Int {
        return when (items[position].type) {
            PostType.UPDATE -> UPDATE
            PostType.MEDIA  -> MEDIA
            PostType.STORY  -> STORY
            PostType.LINK   -> LINK
            else            -> error("unsupported type")
        }
    }

    open class VH(view: View, private val period: Period) : RecyclerView.ViewHolder(view) {
        protected fun getInfo(item: PostModelView): Spanned {
            val context = itemView.context!!
            val date = DateTimeUtil.millisToString(
                item.timestamp, if (period == Period.DECADE) {
                    DateTimeUtil.DATE_FORMAT_2
                } else {
                    DateTimeUtil.DATE_FORMAT_3
                }, DateTimeUtil.defaultTimeZone()
            )
            val time = DateTimeUtil.millisToString(
                item.timestamp,
                DateTimeUtil.TIME_FORMAT_1,
                DateTimeUtil.defaultTimeZone()
            )
            val info = StringBuilder(context.getString(R.string.date_format_1).format(date, time))
            val tags = item.tags
            val firstTag = if (tags.isNotEmpty()) tags[0].removeQuote() else null
            if (firstTag != null) {
                info.append(" ")
                if (item.hasSingleTag()) {
                    info.append(context.getString(R.string.with_format_1).format(firstTag))
                } else {
                    info.append(
                        context.getString(R.string.with_format_2).format(
                            firstTag,
                            tags.size - 1
                        )
                    )
                }
            }
            if (item.hasLocation()) {
                info.append(" ").append(context.getString(R.string.at_format).format(item.location))
            }
            return info.toString().toHtmlSpan()
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

    class MediaVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoMedia.text = getInfo(item)
                tvCaptionMedia.text = item.content
                ivPhoto.load(item.url ?: item.thumbnail ?: "", item.uri)
            }
        }
    }

    class StoryVH(view: View, period: Period) : VH(view, period) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoStory.text = getInfo(item)
                tvCaptionStory.text = item.title
                ivStory.load(item.url ?: "", item.uri)
            }
        }
    }

    class LinkVH(view: View, period: Period) : VH(view, period) {

        init {
            with(itemView) {
                tvLink.setOnClickListener {
                    val link = tvLink.text.toString()
                    if (link.isNotEmpty()) {
                        Navigator.openBrowser(context, link)
                    }
                }
            }
        }

        fun bind(item: PostModelView) {
            with(itemView) {
                tvLinkInfo.text = getInfo(item)
                tvTitle.text = item.content
                if (item.url != null) {
                    val spannableString = SpannableString(item.url)
                    spannableString.setSpan(
                        NoUnderlineSpan(),
                        0,
                        item.url.length,
                        Spanned.SPAN_INCLUSIVE_EXCLUSIVE
                    )
                    tvLink.text = spannableString
                }
            }
        }
    }
}