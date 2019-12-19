/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.postdetail

import android.os.Bundle
import android.view.View
import androidx.core.content.ContextCompat
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.GroupName
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.fromString
import com.bitmark.fbm.data.model.entity.value
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.EndlessScrollListener
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.view.statistic.GroupView
import com.bitmark.fbm.util.view.statistic.getPostType
import kotlinx.android.synthetic.main.fragment_usage_detail.*
import javax.inject.Inject


class PostDetailFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "PostDetailFragment"

        private const val CHART_ITEM = "chart_item"

        private const val TITLE = "title"

        private const val PERIOD_DETAIL = "period_detail"

        private const val SUB_TITLE = "sub_title"

        private const val PERIOD = "period"

        private const val STARTED_AT_SEC = "started_at_sec"

        private const val ENDED_AT_SEC = "ended_at_sec"

        fun newInstance(
            title: String,
            periodDetail: String,
            period: Period,
            subTitle: String? = null,
            startedAtSec: Long,
            endedAtSec: Long,
            chartItem: GroupView.ChartItem
        ): PostDetailFragment {
            val fragment = PostDetailFragment()
            val bundle = Bundle()
            bundle.putString(TITLE, title)
            bundle.putString(PERIOD_DETAIL, periodDetail)
            bundle.putString(PERIOD, period.value)
            bundle.putLong(STARTED_AT_SEC, startedAtSec)
            bundle.putLong(ENDED_AT_SEC, endedAtSec)
            bundle.putParcelable(CHART_ITEM, chartItem)
            if (subTitle != null) bundle.putString(SUB_TITLE, subTitle)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var viewModel: PostDetailViewModel

    @Inject
    internal lateinit var navigator: Navigator

    private var startedAtSec = -1L

    private var endedAtSec = -1L

    private lateinit var endlessScrollListener: EndlessScrollListener

    private lateinit var chartItem: GroupView.ChartItem

    private lateinit var adapter: PostDetailRecyclerViewAdapter

    override fun layoutRes(): Int = R.layout.fragment_usage_detail

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val periodRange = chartItem.periodRange
        if (periodRange != null) {
            listPost(chartItem, periodRange.first / 1000, periodRange.last / 1000)
        } else {
            listPost(chartItem, startedAtSec, endedAtSec)
        }
    }

    override fun initComponents() {
        super.initComponents()

        val title = arguments?.getString(TITLE) ?: error("missing TITLE")
        val period = arguments?.getString(PERIOD) ?: error("missing PERIOD")
        val periodDetail = arguments?.getString(PERIOD_DETAIL) ?: error("missing PERIOD_DETAIL")
        val subTitle = arguments?.getString(SUB_TITLE)
        startedAtSec = arguments?.getLong(STARTED_AT_SEC) ?: error("missing STARTED_AT_SEC")
        endedAtSec = arguments?.getLong(ENDED_AT_SEC) ?: error("missing ENDED_AT_SEC")
        chartItem = arguments?.getParcelable(CHART_ITEM) as? GroupView.ChartItem
            ?: error("missing CHART_ITEM")

        tvTitle.text = title
        tvPeriod.text = periodDetail
        if (subTitle != null) tvTitleSuffix.text = subTitle

        val layoutManager = LinearLayoutManager(context, RecyclerView.VERTICAL, false)
        rv.layoutManager = layoutManager
        endlessScrollListener = object : EndlessScrollListener(layoutManager) {
            override fun onLoadMore(page: Int, totalItemsCount: Int, view: RecyclerView) {
                if (chartItem.periodRange != null) {
                    listPost(chartItem, chartItem.periodRange!!.first / 1000)
                } else {
                    listPost(chartItem, startedAtSec)
                }
            }
        }
        rv.addOnScrollListener(endlessScrollListener)
        val itemDecoration = DividerItemDecoration(context, RecyclerView.VERTICAL)
        val dividerDrawable =
            ContextCompat.getDrawable(context!!, R.drawable.double_divider_white)
        if (dividerDrawable != null) itemDecoration.setDrawable(dividerDrawable)
        rv.addItemDecoration(itemDecoration)
        adapter = PostDetailRecyclerViewAdapter(Period.fromString(period))
        rv.adapter = adapter

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).popChildFragment()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.listPostLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    val data = res.data() ?: return@Observer
                    adapter.add(data)
                }

                res.isError()   -> {
                    Tracer.ERROR.log(TAG, res.throwable()?.message ?: "unknown")
                    progressBar.gone()
                }

                res.isLoading() -> {
                    progressBar.visible()
                }
            }
        })
    }

    private fun listPost(
        chartItem: GroupView.ChartItem,
        startedAtSec: Long,
        endedAtSec: Long? = null
    ) {
        when (chartItem.groupName) {
            GroupName.TYPE   -> {
                val postType = chartItem.getPostType()!!
                if (endedAtSec != null) {
                    viewModel.listPostByType(postType, startedAtSec, endedAtSec)
                } else {
                    viewModel.listNextPostByType(postType, startedAtSec)
                }

            }

            GroupName.DAY    -> {
                if (endedAtSec != null) {
                    viewModel.listPost(startedAtSec, endedAtSec)
                } else {
                    viewModel.listNextPost(startedAtSec)
                }
            }

            GroupName.FRIEND -> {
                if (endedAtSec != null) {
                    viewModel.listPostByTag(chartItem.entryVal, startedAtSec, endedAtSec)
                } else {
                    viewModel.listNextPostByTag(chartItem.entryVal, startedAtSec)
                }
            }

            GroupName.PLACE  -> {
                if (endedAtSec != null) {
                    viewModel.listPostByLocation(chartItem.entryVal, startedAtSec, endedAtSec)
                } else {
                    viewModel.listNextPostByLocation(chartItem.entryVal, startedAtSec)
                }
            }
            else             -> error("unsupported group name ${chartItem.groupName.value}")
        }
    }

    override fun onBackPressed(): Boolean {
        return navigator.anim(RIGHT_LEFT).popChildFragment()
    }
}