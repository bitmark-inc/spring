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
import com.bitmark.fbm.feature.locationdetail.LocationDetailFragment
import com.bitmark.fbm.feature.postdetail.PostDetailFragment
import com.bitmark.fbm.feature.reactiondetail.ReactionDetailFragment
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.Constants
import com.bitmark.fbm.util.DateTimeUtil
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

    @Inject
    internal lateinit var logger: EventLogger

    @Statistic.Type
    private lateinit var type: String

    private lateinit var period: Period

    private var periodStartedAtSec = -1L

    private var periodGap = -1

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

        periodGap = getDefaultPeriodGap(period)
        periodStartedAtSec = getStartOfPeriodSec(period)
    }

    override fun onResume() {
        super.onResume()
        if (adapter.itemCount > 0) return
        handler.postDelayed({
            viewModel.getStatistic(type, period, periodStartedAtSec)
        }, Constants.MASTER_DELAY_TIME)
    }

    override fun initComponents() {
        super.initComponents()

        ivNextPeriod.isEnabled = periodStartedAtSec != getStartOfPeriodSec(period)
        showPeriod(period, periodStartedAtSec, periodGap)

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

        ivNextPeriod.setOnClickListener {
            periodGap--
            periodStartedAtSec =
                getStartOfPeriodSec(period, periodStartedAtSec, true)
            showPeriod(period, periodStartedAtSec, periodGap)
            viewModel.getStatistic(type, period, periodStartedAtSec)
        }

        ivPrevPeriod.setOnClickListener {
            periodGap++
            periodStartedAtSec =
                getStartOfPeriodSec(period, periodStartedAtSec, false)
            showPeriod(period, periodStartedAtSec, periodGap)
            viewModel.getStatistic(type, period, periodStartedAtSec)
        }

    }

    private fun showPeriod(period: Period, periodStartedAtSec: Long, periodGap: Int) {
        ivNextPeriod.isEnabled = periodStartedAtSec != getStartOfPeriodSec(period)
        ivPrevPeriod.isEnabled = getStartOfPeriodSec(period, periodStartedAtSec, false) >= 0L
        val periodStartedAtMillis = periodStartedAtSec * 1000
        tvTime.text = DateTimeUtil.formatPeriod(period, periodStartedAtMillis)
        val defaultPeriodGap = getDefaultPeriodGap(period)
        if (defaultPeriodGap == periodGap) {
            tvType.text = getString(
                when (period) {
                    Period.WEEK   -> R.string.last_week
                    Period.YEAR   -> R.string.this_year
                    Period.DECADE -> R.string.this_decade
                }
            )
        } else {
            val plural = periodGap > 1
            tvType.text = getString(
                when (period) {
                    Period.WEEK   -> if (plural) R.string.last_week_format_plural else R.string.last_week
                    Period.YEAR   -> if (plural) R.string.last_year_format_plural else R.string.last_year
                    Period.DECADE -> if (plural) R.string.last_decade_format_plural else R.string.last_decade
                }
            ).format(periodGap)
        }

    }

    private fun getDefaultPeriodGap(period: Period) = when (period) {
        Period.WEEK -> 1 // last week by default
        else        -> 0
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
                    val data = res.data() ?: return@Observer
                    if (data.any { s -> s.periodStartedAtSec != periodStartedAtSec }) return@Observer
                    adapter.set(data)
                }

                res.isError()   -> {
                    Tracer.ERROR.log(TAG, res.throwable()?.message ?: "unknown")
                    logger.logError(
                        Event.LOAD_STATISTIC_ERROR,
                        res.throwable()?.message ?: "unknown"
                    )
                    adapter.clear()
                    dialogController.alert(
                        R.string.error,
                        R.string.there_was_error_when_loading_statistic
                    )
                }

                res.isLoading() -> {
                }
            }
        })
    }

    private fun handleChartClicked(chartItem: GroupView.ChartItem) {
        if (chartItem.yVal == 0f) return
        val periodStartedAtMillis = periodStartedAtSec * 1000
        val endedAtSec = when (period) {
            Period.WEEK   -> DateTimeUtil.getEndOfWeek(periodStartedAtMillis)
            Period.YEAR   -> DateTimeUtil.getEndOfYearMillis(periodStartedAtMillis)
            Period.DECADE -> DateTimeUtil.getEndOfDecade(periodStartedAtMillis)
        } / 1000
        val startedAtSec = periodStartedAtSec

        val title = getString(
            when (chartItem.sectionName) {
                SectionName.POST        -> chartItem.stringRes ?: R.string.posts
                SectionName.REACTION    -> chartItem.stringRes ?: R.string.reactions
                SectionName.MESSAGE     -> R.string.messages
                SectionName.AD_INTEREST -> R.string.ad_interests
                SectionName.ADVERTISER  -> R.string.advertisers
                SectionName.LOCATION    -> R.string.locations
                else                    -> R.string.empty
            }
        )

        val titleSuffix = when (chartItem.sectionName) {
            SectionName.POST     -> {
                when (chartItem.groupName) {
                    GroupName.FRIEND -> getString(R.string.tagged_with_lower_format).format(
                        chartItem.xVal
                    )
                    GroupName.PLACE  -> getString(R.string.tagged_at_lower_format).format(chartItem.xVal)
                    else             -> ""
                }
            }

            SectionName.REACTION -> {
                when (chartItem.groupName) {
                    GroupName.FRIEND -> getString(R.string.reacted_to_lower_format).format(chartItem.xVal)
                    else             -> ""
                }
            }

            else                 -> ""
        }

        val periodDetail = if (chartItem.groupName == GroupName.SUB_PERIOD) {
            DateTimeUtil.formatSubPeriod(
                period,
                chartItem.periodRange!!.first * 1000,
                DateTimeUtil.defaultTimeZone()
            )
        } else {
            DateTimeUtil.formatPeriod(
                period,
                periodStartedAtMillis,
                DateTimeUtil.defaultTimeZone()
            )
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

            SectionName.LOCATION -> {
                navigator.anim(RIGHT_LEFT).replaceChildFragment(
                    R.id.layoutContainer,
                    LocationDetailFragment.newInstance(
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

        }
    }

    private fun getStartOfPeriodSec(period: Period) = when (period) {
        Period.WEEK   -> DateTimeUtil.getStartOfLastWeekMillis()
        Period.YEAR   -> DateTimeUtil.getStartOfThisYearMillis()
        Period.DECADE -> DateTimeUtil.getStartOfThisDecadeMillis()
    } / 1000

    private fun getStartOfPeriodSec(period: Period, sec: Long, next: Boolean): Long {
        val millis = sec * 1000
        return when (period) {
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
        } / 1000
    }

}