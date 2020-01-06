/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.postdetail

import android.content.Context
import android.text.SpannableString
import android.text.Spanned
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RelativeLayout
import androidx.appcompat.widget.AppCompatImageView
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.getDimensionPixelSize
import com.bitmark.fbm.util.ext.load
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.toHtmlSpan
import com.bitmark.fbm.util.modelview.PostModelView
import com.bitmark.fbm.util.modelview.hasLocation
import com.bitmark.fbm.util.modelview.isMultiMediaPost
import com.bitmark.fbm.util.modelview.mediaType
import com.bitmark.fbm.util.view.Media
import com.bitmark.fbm.util.view.NoUnderlineSpan
import com.bitmark.fbm.util.view.VideoView
import kotlinx.android.synthetic.main.item_link.view.*
import kotlinx.android.synthetic.main.item_multi_media.view.*
import kotlinx.android.synthetic.main.item_photo.view.*
import kotlinx.android.synthetic.main.item_story.view.*
import kotlinx.android.synthetic.main.item_update.view.*
import kotlinx.android.synthetic.main.item_video.view.*


class PostDetailRecyclerViewAdapter(private val period: Period) :
    RecyclerView.Adapter<RecyclerView.ViewHolder>() {

    companion object {
        private const val UPDATE = 0x01
        private const val PHOTO = 0x02
        private const val VIDEO = 0x03
        private const val STORY = 0x04
        private const val LINK = 0x05
        private const val MULTI_MEDIA = 0x06
    }

    private val items = mutableListOf<PostModelView>()

    private var itemClickListener: OnItemClickListener? = null

    fun setItemClickListener(listener: OnItemClickListener) {
        this.itemClickListener = listener
    }

    fun add(items: List<PostModelView>) {
        val pos = this.items.size
        this.items.addAll(items)
        notifyItemRangeInserted(pos, items.size)
    }

    fun isEmpty() = itemCount == 0

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(
            when (viewType) {
                UPDATE      -> R.layout.item_update
                PHOTO       -> R.layout.item_photo
                VIDEO       -> R.layout.item_video
                STORY       -> R.layout.item_story
                LINK        -> R.layout.item_link
                MULTI_MEDIA -> R.layout.item_multi_media
                else        -> error("invalid view type")
            }, parent, false
        )
        return when (viewType) {
            UPDATE      -> UpdateVH(view, period, itemClickListener)
            PHOTO       -> PhotoVH(view, period, itemClickListener)
            VIDEO       -> VideoVH(view, period, itemClickListener)
            STORY       -> StoryVH(view, period, itemClickListener)
            LINK        -> LinkVH(view, period, itemClickListener)
            MULTI_MEDIA -> MultiMediaVH(view, period, itemClickListener)
            else        -> error("invalid view type")
        }
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        val item = items[position]
        when (getItemViewType(position)) {
            UPDATE      -> (holder as UpdateVH).bind(item)
            PHOTO       -> (holder as PhotoVH).bind(item)
            VIDEO       -> (holder as VideoVH).bind(item)
            STORY       -> (holder as StoryVH).bind(item)
            LINK        -> (holder as LinkVH).bind(item)
            MULTI_MEDIA -> (holder as MultiMediaVH).bind(item)
        }
    }

    override fun getItemViewType(position: Int): Int {
        val item = items[position]
        return when (item.type) {
            PostType.UPDATE -> UPDATE
            PostType.MEDIA  -> if (item.isMultiMediaPost()) MULTI_MEDIA else if (item.mediaType == MediaType.PHOTO) PHOTO else VIDEO
            PostType.STORY  -> STORY
            PostType.LINK   -> LINK
            else            -> error("unsupported type")
        }
    }

    open class VH(
        view: View,
        private val period: Period,
        protected val listener: OnItemClickListener?
    ) : RecyclerView.ViewHolder(view) {

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
            val firstTag = if (tags.isNotEmpty()) tags[0] else null
            if (firstTag != null) {
                info.append(" ")
                when (tags.size) {
                    1    -> {
                        info.append(context.getString(R.string.with_format_1).format(firstTag))
                    }
                    2    -> {
                        info.append(
                            context.getString(R.string.with_format_4).format(
                                item.tags[0],
                                item.tags[1]
                            )
                        )
                    }
                    else -> {
                        val displayTags = tags.take(2)
                        info.append(
                            context.getString(if (tags.size == 3) R.string.with_format_3 else R.string.with_format_2).format(
                                displayTags[0],
                                displayTags[1],
                                tags.size - 2
                            )
                        )
                    }
                }
            }
            if (item.hasLocation()) {
                info.append(" ").append(context.getString(R.string.at_format).format(item.location))
            }
            return info.toString().toHtmlSpan()
        }
    }

    class UpdateVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfo.text = getInfo(item)
                tvContent.text = item.content
            }
        }
    }

    class MultiMediaVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        companion object {
            private const val MEDIA_INDEX = 2
        }

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoMedia.text = getInfo(item)
                tvCaptionMedia.text = item.content

                val root = itemView as? LinearLayout ?: error("invalid root layout")
                val firstMediaView = root.getChildAt(MEDIA_INDEX)
                if (firstMediaView != null) {
                    val childCount = root.childCount
                    root.removeViews(MEDIA_INDEX, childCount - MEDIA_INDEX)
                }

                for (mediaData in item.mediaData!!) {
                    val view = when (MediaType.fromString(mediaData.type)) {
                        MediaType.PHOTO -> {
                            val imageView = AppCompatImageView(context)
                            imageView.adjustViewBounds = true
                            imageView.scaleType = ImageView.ScaleType.CENTER_CROP
                            imageView.load(mediaData.canonicalSource, mediaData.source)
                            imageView
                        }
                        MediaType.VIDEO -> {
                            val videoView = VideoView(context)
                            val media = Media(mediaData.canonicalSource, mediaData.source)
                            if (mediaData.thumbnail != null) {
                                videoView.showThumbnail(media) {
                                    videoView.showDefaultThumbnail()
                                }
                            } else {
                                videoView.showDefaultThumbnail()
                            }
                            videoView.setPlayClickListener { m ->
                                listener?.onVideoPlayClicked(m.url)
                            }
                            videoView
                        }
                    }
                    view.layoutParams = getParams(context)
                    root.addView(view)
                }
            }
        }

        private fun getParams(context: Context): RelativeLayout.LayoutParams {
            val params = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                context.getDimensionPixelSize(R.dimen.dp_340)
            )
            params.setMargins(0, context.getDimensionPixelSize(R.dimen.dp_24), 0, 0)
            return params
        }
    }

    class VideoVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        private lateinit var item: PostModelView

        init {
            with(itemView) {
                ivPlayVideo.setSafetyOnclickListener {
                    listener?.onVideoPlayClicked(item.url ?: "")
                }
            }
        }

        fun bind(item: PostModelView) {
            this.item = item
            with(itemView) {
                tvInfoVideo.text = getInfo(item)
                tvCaptionVideo.text = item.content
                if (item.thumbnail == null) {
                    ivVideoThumbnail.setBackgroundColor(context.getColor(R.color.athens_gray))
                } else {
                    ivVideoThumbnail.load(item.thumbnail, item.uri, error = {
                        ivVideoThumbnail.setBackgroundColor(context.getColor(R.color.athens_gray))
                    })
                }
            }
        }
    }

    class PhotoVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoPhoto.text = getInfo(item)
                tvCaptionPhoto.text = item.content
                ivPhoto.load(item.url!!, item.uri)
            }
        }
    }

    class StoryVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        fun bind(item: PostModelView) {
            with(itemView) {
                tvInfoStory.text = getInfo(item)
                tvCaptionStory.text = item.title
                ivStory.load(item.url ?: "", item.uri)
            }
        }
    }

    class LinkVH(view: View, period: Period, listener: OnItemClickListener?) :
        VH(view, period, listener) {

        init {
            with(itemView) {
                tvLink.setOnClickListener {
                    val link = tvLink.text.toString()
                    listener?.onLinkClicked(link)
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

interface OnItemClickListener {

    fun onVideoPlayClicked(uri: String)

    fun onLinkClicked(url: String)
}