/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import android.content.Context
import android.os.Bundle
import android.os.Handler
import androidx.core.content.ContextCompat
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.SimpleItemAnimator
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.*
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.feature.postdetail.PostDetailFragment
import com.bitmark.fbm.feature.reactiondetail.ReactionDetailFragment
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.Constants
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.ext.gone
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.ext.visible
import com.bitmark.fbm.util.formatPeriod
import com.bitmark.fbm.util.formatSubPeriod
import com.bitmark.fbm.util.view.statistic.GroupView
import kotlinx.android.synthetic.main.fragment_statistic.*
import javax.inject.Inject


class StatisticFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "StatisticFragment"

        private const val TYPE = "type"

        private const val PERIOD = "period"

        fun newInstance(@Statistic.Type type: String, period: Period): StatisticFragment {
            val fragment = StatisticFragment()
            val bundle = Bundle()
            bundle.putString(TYPE, type)
            bundle.putString(PERIOD, period.value)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var viewModel: StatisticViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var dialogController: DialogController

    @Statistic.Type
    private lateinit var type: String

    private lateinit var period: Period

    private var periodStartedTime = -1L

    private var blocked = false

    private val handler = Handler()

    private lateinit var adapter: StatisticRecyclerViewAdapter

    override fun layoutRes(): Int = R.layout.fragment_statistic

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onAttach(context: Context) {
        super.onAttach(context)

        type = arguments?.getString(TYPE) ?: throw IllegalArgumentException("missing type")
        period = Period.fromString(
            arguments?.getString(PERIOD) ?: throw IllegalArgumentException("missing period")
        )

        periodStartedTime = getStartOfPeriod(period)
    }

    override fun onResume() {
        super.onResume()
        if (adapter.itemCount > 0) return
        handler.postDelayed({
            viewModel.getStatistic(type, period, periodStartedTime)
        }, Constants.MASTER_DELAY_TIME)
    }

    override fun initComponents() {
        super.initComponents()

        ivNextPeriod.isEnabled = periodStartedTime != getStartOfPeriod(period)
        tvType.text = when (period) {
            Period.WEEK   -> getString(R.string.last_week)
            Period.YEAR   -> getString(R.string.this_year)
            Period.DECADE -> getString(R.string.this_decade)
        }

        tvTime.text = DateTimeUtil.formatPeriod(period, periodStartedTime)

        adapter = StatisticRecyclerViewAdapter(context!!)
        val layoutManager = LinearLayoutManager(context, RecyclerView.VERTICAL, false)
        rvStatistic.layoutManager = layoutManager
        val itemDecoration = DividerItemDecoration(context, RecyclerView.VERTICAL)
        val dividerDrawable =
            ContextCompat.getDrawable(context!!, R.drawable.double_divider_white_black_stroke)
        if (dividerDrawable != null) itemDecoration.setDrawable(dividerDrawable)
        rvStatistic.addItemDecoration(itemDecoration)
        (rvStatistic.itemAnimator as? SimpleItemAnimator)?.supportsChangeAnimations = false
        rvStatistic.isNestedScrollingEnabled = false
        rvStatistic.adapter = adapter

        adapter.setChartClickListener(object : GroupView.ChartClickListener {
            override fun onClick(chartItem: GroupView.ChartItem) {
                handleChartClicked(chartItem)
            }
        })

        ivNextPeriod.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            periodStartedTime = getStartOfPeriodMillis(period, periodStartedTime, true)
            ivNextPeriod.isEnabled = periodStartedTime != getStartOfPeriod(period)
            tvTime.text = DateTimeUtil.formatPeriod(period, periodStartedTime)
            viewModel.getStatistic(type, period, periodStartedTime)
        }

        ivPrevPeriod.setSafetyOnclickListener {
            if (blocked) return@setSafetyOnclickListener
            periodStartedTime = getStartOfPeriodMillis(period, periodStartedTime, false)
            ivNextPeriod.isEnabled = periodStartedTime != getStartOfPeriod(period)
            tvTime.text = DateTimeUtil.formatPeriod(period, periodStartedTime)
            viewModel.getStatistic(type, period, periodStartedTime)
        }

    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.getStatisticLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    progressBar.gone()
                    val data = res.data() ?: return@Observer
                    adapter.set(data)
                    blocked = false
                }

                res.isError()   -> {
                    progressBar.gone()
                    Tracer.ERROR.log(TAG, res.throwable()?.message ?: "unknown")
                    blocked = false
                }

                res.isLoading() -> {
                    blocked = true
                    progressBar.visible()
                }
            }
        })
    }

    private fun handleChartClicked(chartItem: GroupView.ChartItem) {
        val endedAtSec = when (period) {
            Period.WEEK   -> DateTimeUtil.getEndOfWeek(periodStartedTime)
            Period.YEAR   -> DateTimeUtil.getEndOfYear(periodStartedTime)
            Period.DECADE -> DateTimeUtil.getEndOfDecade(periodStartedTime)
        } / 1000
        val startedAtSec = periodStartedTime / 1000

        val title = getString(
            when (chartItem.sectionName) {
                SectionName.POST        -> R.string.posts
                SectionName.REACTION    -> R.string.reactions
                SectionName.MESSAGE     -> R.string.messages
                SectionName.AD_INTEREST -> R.string.ad_interests
                SectionName.ADVERTISER  -> R.string.advertisers
                SectionName.LOCATION    -> R.string.locations
            }
        )

        val titleSuffix = when (chartItem.sectionName) {
            SectionName.POST     -> {
                when (chartItem.groupName) {
                    GroupName.FRIEND -> getString(R.string.tagged_with_lower_format).format(
                        chartItem.entryVal
                    )
                    GroupName.PLACE  -> getString(R.string.tagged_at_lower_format).format(chartItem.entryVal)
                    else             -> ""
                }
            }

            SectionName.REACTION -> {
                when (chartItem.groupName) {
                    GroupName.FRIEND -> getString(R.string.reacted_to_lower_format).format(chartItem.entryVal)
                    else             -> ""
                }
            }

            else                 -> ""
        }

        val periodDetail = if (chartItem.groupName == GroupName.DAY) {
            DateTimeUtil.formatSubPeriod(period, chartItem.periodRange!!.first)
        } else {
            DateTimeUtil.formatPeriod(period, periodStartedTime)
        }

        when (chartItem.sectionName) {
            SectionName.POST     -> {
                navigator.anim(RIGHT_LEFT).replaceChildFragment(
                    R.id.layoutContainer,
                    PostDetailFragment.newInstance(
                        title,
                        periodDetail,
                        period,
                        titleSuffix,
                        startedAtSec,
                        endedAtSec,
                        chartItem
                    )
                )
            }

            SectionName.REACTION -> {
                navigator.anim(RIGHT_LEFT).replaceChildFragment(
                    R.id.layoutContainer,
                    ReactionDetailFragment.newInstance(
                        title,
                        periodDetail,
                        period,
                        titleSuffix,
                        startedAtSec,
                        endedAtSec,
                        chartItem
                    )
                )
            }

            SectionName.MESSAGE  -> {
                // TODO implement later
            }

        }
    }

    private fun getStartOfPeriod(period: Period) = when (period) {
        Period.WEEK   -> DateTimeUtil.getStartOfLastWeekMillis()
        Period.YEAR   -> DateTimeUtil.getStartOfThisYearMillis()
        Period.DECADE -> DateTimeUtil.getStartOfThisDecadeMillis()
    }

    private fun getStartOfPeriodMillis(period: Period, millis: Long, next: Boolean) =
        when (period) {
            Period.WEEK   -> if (next) {
                DateTimeUtil.getStartOfNextWeekMillis(millis)
            } else {
                DateTimeUtil.getStartOfLastWeekMillis(millis)
            }
            Period.YEAR   -> if (next) {
                DateTimeUtil.getStartOfNextYearMillis(millis)
            } else {
                DateTimeUtil.getStartOfLastYearMillis(millis)
            }
            Period.DECADE -> if (next) {
                DateTimeUtil.getStartOfNextDecadeMillis(millis)
            } else {
                DateTimeUtil.getStartOfLastDecadeMillis(millis)
            }
        }

}