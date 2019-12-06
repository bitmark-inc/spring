/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.usagedetail

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.core.content.ContextCompat
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.model.entity.PostType
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.formatPeriod
import com.bitmark.fbm.util.view.statistic.GroupView
import kotlinx.android.synthetic.main.fragment_usage_detail.*
import javax.inject.Inject


class UsageDetailFragment : BaseSupportFragment() {

    companion object {

        private const val CHART_ITEM = "chart_item"

        private const val PERIOD = "period"

        private const val PERIOD_STARTED_TIME = "period_started_time"

        fun newInstance(
            period: Period,
            periodStartedTime: Long,
            chartItem: GroupView.ChartItem
        ): UsageDetailFragment {
            val fragment = UsageDetailFragment()
            val bundle = Bundle()
            bundle.putParcelable(CHART_ITEM, chartItem)
            bundle.putString(PERIOD, period.value)
            bundle.putLong(PERIOD_STARTED_TIME, periodStartedTime)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var viewModel: UsageDetailViewModel

    @Inject
    internal lateinit var navigator: Navigator

    private lateinit var chartItem: GroupView.ChartItem

    private lateinit var period: Period

    private var periodStartedTime = -1L

    private lateinit var adapter: UsageDetailRecyclerViewAdapter

    override fun layoutRes(): Int = R.layout.fragment_usage_detail

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onAttach(context: Context) {
        super.onAttach(context)

        if (!arguments!!.containsKey(CHART_ITEM)
            || !arguments!!.containsKey(PERIOD)
            || !arguments!!.containsKey(PERIOD_STARTED_TIME)
        ) {
            error("missing CHART_ITEM or PERIOD or PERIOD_STARTED_TIME")
        }

        chartItem = arguments!!.getParcelable(CHART_ITEM) as GroupView.ChartItem
        period = Period.fromString(arguments!!.getString(PERIOD) as String)
        periodStartedTime = arguments!!.getLong(PERIOD_STARTED_TIME)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val to = when (period) {
            Period.WEEK   -> DateTimeUtil.getEndOfWeek(periodStartedTime)
            Period.YEAR   -> DateTimeUtil.getEndOfYear(periodStartedTime)
            Period.DECADE -> DateTimeUtil.getEndOfDecade(periodStartedTime)
        }
        val postType = when (chartItem.entryVal) {
            "updates" -> PostType.UPDATE
            "photos"  -> PostType.PHOTO
            "videos"  -> PostType.VIDEO
            "stories" -> PostType.STORY
            "links"   -> PostType.LINK
            else      -> PostType.UNSPECIFIED
        }
        viewModel.getPost(postType, periodStartedTime, to)
    }

    override fun initComponents() {
        super.initComponents()

        tvTitle.text = chartItem.entryVal
        tvPeriod.text = DateTimeUtil.formatPeriod(period, periodStartedTime)

        val layoutManager = LinearLayoutManager(context, RecyclerView.VERTICAL, false)
        rv.layoutManager = layoutManager
        val itemDecoration = DividerItemDecoration(context, RecyclerView.VERTICAL)
        val dividerDrawable =
            ContextCompat.getDrawable(context!!, R.drawable.double_divider_white)
        if (dividerDrawable != null) itemDecoration.setDrawable(dividerDrawable)
        rv.addItemDecoration(itemDecoration)
        adapter = UsageDetailRecyclerViewAdapter(period)
        rv.adapter = adapter

        ivBack.setOnClickListener {
            navigator.anim(RIGHT_LEFT).popChildFragment()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.getPostLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    val data = res.data() ?: return@Observer
                    adapter.set(data)
                }

                res.isError()   -> {
                    progressBar.gone()
                }

                res.isLoading() -> {
                    progressBar.visible()
                }
            }
        })
    }

    override fun onBackPressed(): Boolean {
        return navigator.anim(RIGHT_LEFT).popChildFragment()
    }
}